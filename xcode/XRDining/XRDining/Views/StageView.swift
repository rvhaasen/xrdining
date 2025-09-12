//
//  Untitled.swift
//  ProtoStageConfig
//
//  Created by Rick van Haasen on 04/09/2025.
//
//
//  ItemsView.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/09/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Model
struct StageItem: Identifiable, Equatable {
    let id: UUID = .init()
    var title: String
    var videoURL: URL? = nil
    var audioURL: URL? = nil
    var duration: Int = 0
    var rotation: Int = 0
    var notes: String = ""
    var isEnabled: Bool = true
    var volume: Float = 1.0
    var pdfURL: URL? = nil
}

// MARK: - Main List
struct StageView: View {
    @Environment(AppModel.self) var appModel
    
    //@State private var items: [StageItem] = []
    @State private var showNewItem = false
    @State private var insertAfterID: UUID? = nil


    var body: some View {
        @Bindable var appModel = appModel
        NavigationStack {
            List {
                ForEach($appModel.items) { $item in
                    NavigationLink {
                        StageEditor(item: $item)
                    } label: {
                        HStack {
                            Text(item.title).font(.body)
                            if item.isEnabled { Image(systemName: "checkmark") }
                            Spacer()
                            Button(action: {
                                insertAfterID = item.id
                                showNewItem = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .imageScale(.large)
                                    .accessibilityLabel("Insert after")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onDelete { appModel.items.remove(atOffsets: $0) }
                .onMove { appModel.items.move(fromOffsets: $0, toOffset: $1) }
            }
            .navigationTitle("Stages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        insertAfterID = nil
                        showNewItem = true
                    } label: {
                        Label("Add Stage", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewItem) {
                NewItemSheet { newItem in
                    if let afterID = insertAfterID, let index = appModel.items.firstIndex(where: { $0.id == afterID }) {
                        appModel.items.insert(newItem, at: index + 1)
                    } else {
                        appModel.items.append(newItem)
                    }
                    insertAfterID = nil
                }
            }
        }
    }
}

// MARK: - New Item Sheet (create)
struct NewItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var videoURL : URL?
    @State private var audioURL: URL?
    @State private var notes: String = ""
    @State private var isEnabled = true
    @State private var duration: Int = 10
    @State private var rotation: Int = 0
    @State private var volume: Float = 1.0
    @State private var pdfURL: URL?
    @State private var showFileImporter = false
    @State private var fileImportError: Error? = nil
    @State private var showBundleVideoPicker = false
    @State private var showBundleAudioPicker = false

    @State private var pickedURL: URL?
    @State private var hasSecurityScope = false
    
    enum ImportType {
        case video
        case audio
        case pdf
    }
    @State private var importType: ImportType? = nil

    let onSave: (StageItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter properties") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Enabled", isOn: $isEnabled)
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", value: $duration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Rotation")
                        Spacer()
                        TextField("0", value: $rotation, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    if let url = videoURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button {
                        importType = .video
                        showFileImporter = true
                    } label: {
                        Label("Select Video", systemImage: "film")
                    }
                    HStack {
                        Text("Volume of audio in video (0 .. 1.0)")
                        Spacer()
                        TextField("1.0", value: $volume, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
//                    Button {
//                        showBundleVideoPicker = true
//                    } label: {
//                        Label("Select video from Bundle...", systemImage: "shippingbox")
//                    }
                    if let url = audioURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button {
                        importType = .audio
                        showFileImporter = true
                    } label: {
                        Label("Select Audio", systemImage: "music.note")
                    }
                    if let url = pdfURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button {
                        importType = .pdf
                        showFileImporter = true
                    } label: {
                        Label("Select meal description PDF", systemImage: "doc.richtext.fill")
                    }
//                    Button {
//                        showBundleAudioPicker = true
//                    } label: {
//                        Label("Select audio from Bundle...", systemImage: "shippingbox")
//                    }
                }
            }
            .navigationTitle("New Stage")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = StageItem(title: title,
                                        videoURL: videoURL,
                                        audioURL: audioURL,
                                        duration: duration,
                                        rotation: rotation,
                                        notes: notes,
                                        isEnabled: isEnabled,
                                        volume: volume,
                                        pdfURL: pdfURL)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: {
                switch importType {
                case .video: [.movie]
                case .audio: [.audio]
                case .pdf:   [.pdf]
                case nil:    []
                }
            }(), allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let selected = urls.first {
                        let url2 = handlePickedURL(selected)
                        if importType == .video {
                            videoURL = url2
                        } else if importType == .audio {
                            audioURL = selected
                        } else if importType == .pdf {
                            pdfURL = selected
                        }
                    }
                case .failure(let error):
                    fileImportError = error
                }
            }
            .sheet(isPresented: $showBundleVideoPicker) {
                BundleVideoPicker { selected in
                    print("Starting Bundle Video Picker...")
                    if let selected = selected {
                        #if canImport(UIKit)
                        print("Selecting videoURL...")
                        if let url = Bundle.main.url(forResource: selected, withExtension: "mp4") {
                            videoURL = url
                            print("Selected videoURL \(url)")
                        }
                        #endif
                    }
                    showBundleVideoPicker = false
                }
            }
            .sheet(isPresented: $showBundleAudioPicker) {
                BundleAudioPicker { selected in
                    if let selected = selected {
                        #if canImport(UIKit)
                        if let url = Bundle.main.url(forResource: selected, withExtension: "m4a") ?? Bundle.main.url(forResource: selected, withExtension: "mp3") {
                            audioURL = url
                        }
                        #endif
                    }
                    showBundleAudioPicker = false
                }
            }
        }
    }
    private func handlePickedURL(_ url: URL) -> URL {
        // Clean up previous selection
        stopAccessIfNeeded()

        // Gain access to a security-scoped file from Files/iCloud
        hasSecurityScope = url.startAccessingSecurityScopedResource()

        // If this lives in iCloud, trigger download if needed
        if FileManager.default.isUbiquitousItem(at: url) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }

        //pickedURL = url
        //player = AVPlayer(url: url)
        //player?.automaticallyWaitsToMinimizeStalling = true
        //player?.play()
        return url
    }

    private func stopAccessIfNeeded() {
        if hasSecurityScope, let pickedURL {
            pickedURL.stopAccessingSecurityScopedResource()
        }
        hasSecurityScope = false
    }
}

// MARK: - Editor (edit existing)
struct StageEditor: View {
    @Binding var item: StageItem
    @State private var fileImportError: Error?
    //@State private var duration: Int
    @State private var showBundleVideoPicker = false
    @State private var showBundleAudioPicker = false
    @State private var showFileImporter = false
    
    @State private var pickedURL: URL?
    @State private var hasSecurityScope = false
    
    enum ImportType {
        case video
        case audio
        case pdf
    }
    @State private var importType: ImportType? = nil

    init(item: Binding<StageItem>) {
        self._item = item
        
        //self._duration = State(initialValue: item.wrappedValue.duration)
    }

    var body: some View {
        Form {
            Section("Enter properties") {
                TextField("Title", text: $item.title)
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(3...6)
                Toggle("Enabled", isOn: $item.isEnabled)
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("0", value: $item.duration, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("Rotation")
                    Spacer()
                    TextField("0", value: $item.rotation, format: .number)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                if let url = item.videoURL {
                    Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                }
                Button {
                    importType = .video
                    showFileImporter = true
                } label: {
                    Label("Select Video", systemImage: "film")
                }
                HStack {
                    Text("Volume of audio in video (0 .. 1.0)")
                    Spacer()
                    TextField("1.0", value: $item.volume, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
//                Button {
//                    showBundleVideoPicker = true
//                } label: {
//                    Label("Select video from Bundle...", systemImage: "shippingbox")
//                }
                if let url = item.audioURL {
                    Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                }
                Button {
                    importType = .audio
                    showFileImporter = true
                } label: {
                    Label("Select Audio", systemImage: "music.note")
                }
                if let url = item.pdfURL {
                    Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                }
                Button {
                    importType = .pdf
                    showFileImporter = true
                } label: {
                    Label("Select meal description PDF", systemImage: "doc.richtext.fill")
                }
//                Button {
//                    showBundleAudioPicker = true
//                } label: {
//                    Label("Select audio from Bundle...", systemImage: "shippingbox")
//                }
            }
        }
        .navigationTitle("Edit Item")
//        .onDisappear {
//            item.duration = duration
//        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: {
            switch importType {
            case .video: [.movie]
            case .audio: [.audio]
            case .pdf:   [.pdf]
            case nil:    []
            }
        }(), allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let selected = urls.first {
                    let url2 = handlePickedURL(selected)
                    if importType == .video {
                        item.videoURL = url2
                    } else if importType == .audio {
                        item.audioURL = selected
                    } else if importType == .pdf {
                        item.pdfURL = selected
                    }
                }
            case .failure(let error):
                fileImportError = error
            }
        }
//        .fileImporter(isPresented: Binding(get: { importType != nil },
//                                          set: { if !$0 { importType = nil } }),
//                      allowedContentTypes: importType == .video ? [.video] : [.audio],
//                      allowsMultipleSelection: false) { result in
//            switch result {
//            case .success(let urls):
//                if let selected = urls.first {
//                    if importType == .video {
//                        item.videoURL = selected
//                    } else if importType == .audio {
//                        item.audioURL = selected
//                    }
//                }
//            case .failure(let error):
//                fileImportError = error
//            }
//            importType = nil
//        }
        .sheet(isPresented: $showBundleVideoPicker) {
            BundleVideoPicker { selected in
                if let selected = selected {
                    #if canImport(UIKit)
                    if let url = Bundle.main.url(forResource: selected, withExtension: "mp4") {
                        item.videoURL = url
                    }
                    #endif
                }
                showBundleVideoPicker = false
            }
        }
        .sheet(isPresented: $showBundleAudioPicker) {
            BundleAudioPicker { selected in
                if let selected = selected {
                    #if canImport(UIKit)
                    if let url = Bundle.main.url(forResource: selected, withExtension: "m4a") ?? Bundle.main.url(forResource: selected, withExtension: "mp3") {
                        item.audioURL = url
                    }
                    #endif
                }
                showBundleAudioPicker = false
            }
        }
    }
    private func handlePickedURL(_ url: URL) -> URL {
        // Clean up previous selection
        stopAccessIfNeeded()

        // Gain access to a security-scoped file from Files/iCloud
        hasSecurityScope = url.startAccessingSecurityScopedResource()

        // If this lives in iCloud, trigger download if needed
        if FileManager.default.isUbiquitousItem(at: url) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }

        //pickedURL = url
        //player = AVPlayer(url: url)
        //player?.automaticallyWaitsToMinimizeStalling = true
        //player?.play()
        return url
    }

    private func stopAccessIfNeeded() {
        if hasSecurityScope, let pickedURL {
            pickedURL.stopAccessingSecurityScopedResource()
        }
        hasSecurityScope = false
    }
}

// MARK: - Preview
#Preview {
    StageView()
}

// MARK: - Bundle Video Picker

struct BundleVideoPicker: View {
    let onPick: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    private var videos: [String] {
        (Bundle.main.paths(forResourcesOfType: "mp4", inDirectory: nil) as [String])
            .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
    }
    var body: some View {
        NavigationStack {
            List(videos, id: \.self) { name in
                Button(name) { onPick(name); dismiss() }
            }
            Button("Cancel") { onPick(nil); dismiss() }
                .foregroundStyle(.red)
        }
    }
}

struct BundleAudioPicker: View {
    let onPick: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    private var audios: [String] {
        let m4aPaths = Bundle.main.paths(forResourcesOfType: "m4a", inDirectory: nil)
        let mp3Paths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        let allPaths = m4aPaths + mp3Paths
        let names = allPaths
            .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        // Remove duplicates
        return Array(Set(names)).sorted()
    }
    var body: some View {
        NavigationStack {
            List(audios, id: \.self) { name in
                Button(name) { onPick(name); dismiss() }
            }
            Button("Cancel") { onPick(nil); dismiss() }
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    StageView()
        .environment(AppModel())
}
