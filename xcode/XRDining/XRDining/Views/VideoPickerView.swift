//
//  VideoPickerView.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/09/2025.
//
import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct VideoPickerView: View {
    @State private var showImporter = false
    @State private var player: AVPlayer?
    @State private var pickedURL: URL?
    @State private var hasSecurityScope = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Button {
                showImporter = true
            } label: {
                Label("Select Video", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)

            if let player {
                VideoPlayer(player: player)
                    .frame(height: 280)
                    .onDisappear { stopAccessIfNeeded() }

                HStack(spacing: 12) {
                    Button("Play") { player.play() }
                    Button("Pause") { player.pause() }
                }
            } else {
                Text("Pick a video from iCloud Drive / Files to play.")
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.movie], // covers .mp4, .mov, etc.
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handlePickedURL(url)
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }
    }

    private func handlePickedURL(_ url: URL) {
        // Clean up previous selection
        stopAccessIfNeeded()

        // Gain access to a security-scoped file from Files/iCloud
        hasSecurityScope = url.startAccessingSecurityScopedResource()

        // If this lives in iCloud, trigger download if needed
        if FileManager.default.isUbiquitousItem(at: url) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }

        pickedURL = url
        player = AVPlayer(url: url)
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.play()
    }

    private func stopAccessIfNeeded() {
        if hasSecurityScope, let pickedURL {
            pickedURL.stopAccessingSecurityScopedResource()
        }
        hasSecurityScope = false
    }
}

#Preview {
    VideoPickerView()
}
