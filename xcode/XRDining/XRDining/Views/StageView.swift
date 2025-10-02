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
struct StageItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var videoURL: URL? = nil
    var audioURL: URL? = nil
    var duration: Int = 0
    var rotation: Int = 0
    var notes: String = ""
    var isEnabled: Bool = true
    var volume: Float = 1.0
    var pdfURL: URL? = nil
    var usdzURL: URL? = nil
    var modelFromBundle: String = ""

    init(id: UUID = .init(),
         title: String,
         videoURL: URL? = nil,
         audioURL: URL? = nil,
         duration: Int = 0,
         rotation: Int = 0,
         notes: String = "",
         isEnabled: Bool = true,
         volume: Float = 1.0,
         pdfURL: URL? = nil,
         usdzURL: URL? = nil,
         modelFromBundle: String = "") {
        self.id = id
        self.title = title
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.duration = duration
        self.rotation = rotation
        self.notes = notes
        self.isEnabled = isEnabled
        self.volume = volume
        self.pdfURL = pdfURL
        self.usdzURL = usdzURL
        self.modelFromBundle = modelFromBundle
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, rotation, notes, isEnabled, volume, modelFromBundle
        case videoBookmark, audioBookmark, pdfBookmark, usdzBookmark
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(duration, forKey: .duration)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(notes, forKey: .notes)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(volume, forKey: .volume)
        try container.encode(modelFromBundle, forKey: .modelFromBundle)

        if let url = videoURL {
            if let data = try? url.bookmarkData( includingResourceValuesForKeys: nil, relativeTo: nil) {
                try container.encode(data, forKey: .videoBookmark)
            }
        }
        if let url = audioURL {
            if let data = try? url.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil) {
                try container.encode(data, forKey: .audioBookmark)
            }
        }
        if let url = pdfURL {
            if let data = try? url.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil) {
                try container.encode(data, forKey: .pdfBookmark)
            }
        }
        if let url = usdzURL {
            if let data = try? url.bookmarkData( includingResourceValuesForKeys: nil, relativeTo: nil) {
                try container.encode(data, forKey: .usdzBookmark)
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        rotation = try container.decodeIfPresent(Int.self, forKey: .rotation) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        modelFromBundle = try container.decodeIfPresent(String.self, forKey: .modelFromBundle) ?? ""

        func resolve(_ key: CodingKeys) -> URL? {
            guard let data = try? container.decode(Data.self, forKey: key) else { return nil }
            var stale = false
            // Try resolving as a security-scoped bookmark first, fall back to standard if needed
            if let url = try? URL(resolvingBookmarkData: data, relativeTo: nil, bookmarkDataIsStale: &stale) {
                return url
            } else if let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) {
                return url
            } else {
                return nil
            }
        }

        videoURL = resolve(.videoBookmark)
        audioURL = resolve(.audioBookmark)
        pdfURL = resolve(.pdfBookmark)
        usdzURL = resolve(.usdzBookmark)
    }
}

// MARK: - File Persistence Helpers
private func appSupportContainer() throws -> URL {
    let fm = FileManager.default
    let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let dir = base.appendingPathComponent("StageAssets", isDirectory: true)
    if !fm.fileExists(atPath: dir.path) {
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
}

private func subfolderURL(_ name: String) throws -> URL {
    let root = try appSupportContainer()
    let dir = root.appendingPathComponent(name, isDirectory: true)
    let fm = FileManager.default
    if !fm.fileExists(atPath: dir.path) {
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
}

private func uniqueDestinationURL(for sourceURL: URL, in directory: URL) -> URL {
    let fm = FileManager.default
    let ext = sourceURL.pathExtension
    let baseName = sourceURL.deletingPathExtension().lastPathComponent
    var candidate = directory.appendingPathComponent(sourceURL.lastPathComponent)
    var counter = 2
    while fm.fileExists(atPath: candidate.path) {
        let newName = "\(baseName) \(counter)"
        candidate = directory.appendingPathComponent(newName).appendingPathExtension(ext)
        counter += 1
    }
    return candidate
}

private func copyToAppContainer(_ sourceURL: URL, subfolder: String) throws -> URL {
    let fm = FileManager.default

    // Ensure iCloud file is available
    if fm.isUbiquitousItem(at: sourceURL) {
        try? fm.startDownloadingUbiquitousItem(at: sourceURL)
    }

    var needsStop = false
    if sourceURL.startAccessingSecurityScopedResource() {
        needsStop = true
    }
    defer {
        if needsStop { sourceURL.stopAccessingSecurityScopedResource() }
    }

    let destDir = try subfolderURL(subfolder)
    let destURL = uniqueDestinationURL(for: sourceURL, in: destDir)

    // If selecting a file that's already at the destination, just return it
    if sourceURL.standardizedFileURL == destURL.standardizedFileURL {
        return destURL
    }

    do {
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        try fm.copyItem(at: sourceURL, to: destURL)
    } catch {
        // Fallback to read/write in case a coordinated copy fails
        let data = try Data(contentsOf: sourceURL)
        try data.write(to: destURL, options: [.atomic])
    }

    return destURL
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
    @Environment(AppModel.self) var appModel
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
    @State private var modelFromBundle: String = ""
    @State private var usdzURL: URL?
    @State private var showFileImporter = false
    @State private var fileImportError: Error? = nil
    @State private var showBundleVideoPicker = false
    @State private var showBundleAudioPicker = false
    @State private var showBundlePdfPicker = false

    enum ImportType {
        case video
        case audio
        case pdf
        case usdz
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
                    HStack {
                        Button {
                            importType = .video
                            showFileImporter = true
                        } label: {
                            Label("Select Video", systemImage: "film")
                        }
                        if let url = videoURL {
                            Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Volume of audio in video (0 .. 1.0)")
                        Spacer()
                        TextField("1.0", value: $volume, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Button {
                        showBundleVideoPicker = true
                    } label: {
                        Label("Select video from Bundle...", systemImage: "shippingbox")
                    }
                    HStack {
                        Button {
                            importType = .audio
                            showFileImporter = true
                        } label: {
                            Label("Select Audio", systemImage: "music.note")
                        }
                        if let url = audioURL {
                            Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Button {
                            importType = .pdf
                            showFileImporter = true
                        } label: {
                            Label("Select meal description PDF", systemImage: "doc.richtext.fill")
                        }
                        if let url = pdfURL {
                            Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        showBundlePdfPicker = true
                    } label: {
                        Label("Select meal from Bundle...", systemImage: "shippingbox")
                    }
                    Picker("Select model from bundle", selection: $modelFromBundle) {
                        ForEach(appModel.modelsFromBundle, id: \.self) { s in
                            Text(s).tag(s)          // tag must match selection’s type
                        }
                    }
                    .pickerStyle(.menu)             // or .segmented, .wheel, .navigationLink
//                    HStack {
//                        Button {
//                            importType = .usdz
//                            showFileImporter = true
//                        } label: {
//                            Label("Select meal 3D model", systemImage: "cube")
//                        }
//                        if let url = usdzURL {
//                            Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
//                        }
//                    }
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
                                        pdfURL: pdfURL,
                                        usdzURL: usdzURL,
                                        modelFromBundle: modelFromBundle)
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
                case .usdz:  [.usdz]
                case nil:    []
                }
            }(), allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let selected = urls.first, let type = importType {
                        do {
                            switch type {
                            case .video:
                                let local = try copyToAppContainer(selected, subfolder: "Videos")
                                videoURL = local
                            case .audio:
                                let local = try copyToAppContainer(selected, subfolder: "Audio")
                                audioURL = local
                            case .pdf:
                                let local = try copyToAppContainer(selected, subfolder: "PDFs")
                                pdfURL = local
                            case .usdz:
                                let local = try copyToAppContainer(selected, subfolder: "Models")
                                usdzURL = local
                            }
                        } catch {
                            fileImportError = error
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
            .sheet(isPresented: $showBundlePdfPicker) {
                BundlePdfPicker { selected in
                    if let selected = selected {
                        #if canImport(UIKit)
                        if let url = Bundle.main.url(forResource: selected, withExtension: "pdf") {
                            pdfURL = url
                        }
                        #endif
                    }
                    showBundlePdfPicker = false
                }
            }
        }
    }
    private func handlePickedURL(_ url: URL) -> URL {
        // If this lives in iCloud, trigger download if needed
        if FileManager.default.isUbiquitousItem(at: url) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
        return url
    }
}

// MARK: - Editor (edit existing)
struct StageEditor: View {
    @Environment(AppModel.self) var appModel
    @Binding var item: StageItem
    @State private var fileImportError: Error?
    //@State private var duration: Int
    @State private var showBundleVideoPicker = false
    @State private var showBundleAudioPicker = false
    @State private var showBundlePdfPicker = false
    @State private var showFileImporter = false
    
    enum ImportType {
        case video
        case audio
        case pdf
        case usdz
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
                HStack {
                    Button {
                        importType = .video
                        showFileImporter = true
                    } label: {
                        Label("Select Video", systemImage: "film")
                    }
                    if let url = item.videoURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button ("Cancel") {
                        item.videoURL = nil
                    }
                }
                HStack {
                    Text("Volume of audio in video (0 .. 1.0)")
                    Spacer()
                    TextField("1.0", value: $item.volume, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Button {
                    showBundleVideoPicker = true
                } label: {
                    Label("Select video from Bundle...", systemImage: "shippingbox")
                }
                HStack {
                    Button {
                        importType = .audio
                        showFileImporter = true
                    } label: {
                        Label("Select Audio", systemImage: "music.note")
                    }
                    if let url = item.audioURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button ("Cancel") {
                        item.audioURL = nil
                    }
                }
                HStack {
                    Button {
                        importType = .pdf
                        showFileImporter = true
                    } label: {
                        Label("Select meal description PDF", systemImage: "doc.richtext.fill")
                    }
                    if let url = item.pdfURL {
                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button ("Cancel") {
                        item.pdfURL = nil
                    }
                }
                Button {
                    showBundlePdfPicker = true
                } label: {
                    Label("Select meal from Bundle...", systemImage: "shippingbox")
                }
                Picker("Select model from bundle", selection: $item.modelFromBundle) {
                    ForEach(appModel.modelsFromBundle, id: \.self) { s in
                        Text(s).tag(s)          // tag must match selection’s type
                    }
                }
//                HStack {
//                    Button {
//                        importType = .usdz
//                        showFileImporter = true
//                    } label: {
//                        Label("Select meal 3D model", systemImage: "cube")
//                    }
//                    if let url = item.usdzURL {
//                        Text(url.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
//                    }
//                }
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
            case .usdz: [.usdz]
            case nil:    []
            }
        }(), allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let selected = urls.first, let type = importType {
                    do {
                        switch type {
                        case .video:
                            let local = try copyToAppContainer(selected, subfolder: "Videos")
                            item.videoURL = local
                        case .audio:
                            let local = try copyToAppContainer(selected, subfolder: "Audio")
                            item.audioURL = local
                        case .pdf:
                            let local = try copyToAppContainer(selected, subfolder: "PDFs")
                            item.pdfURL = local
                        case .usdz:
                            let local = try copyToAppContainer(selected, subfolder: "Models")
                            item.usdzURL = local
                        }
                    } catch {
                        fileImportError = error
                    }
                }
            case .failure(let error):
                fileImportError = error
            }
        }
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
        .sheet(isPresented: $showBundlePdfPicker) {
            BundlePdfPicker { selected in
                if let selected = selected {
                    #if canImport(UIKit)
                    if let url = Bundle.main.url(forResource: selected, withExtension: "pdf") {
                        item.pdfURL = url
                    }
                    #endif
                }
                showBundlePdfPicker = false
            }
        }

    }
    private func handlePickedURL(_ url: URL) -> URL {
        // If this lives in iCloud, trigger download if needed
        if FileManager.default.isUbiquitousItem(at: url) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
        return url
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
struct BundlePdfPicker: View {
    let onPick: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    private var pdfs: [String] {
        (Bundle.main.paths(forResourcesOfType: "pdf", inDirectory: nil) as [String])
            .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
    }
    var body: some View {
        NavigationStack {
            List(pdfs, id: \.self) { name in
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

