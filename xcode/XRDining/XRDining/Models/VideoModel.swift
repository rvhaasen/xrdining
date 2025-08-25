//
//  VideoModel.swift
//  XRDining
//
//  Created by Rick van Haasen on 28/06/2025.
//

import AVFoundation
import RealityKit

class VideoModel {
    var player: AVPlayer
    var videoMaterial: VideoMaterial
    var isPlaying: Bool = false
    
    enum VideoError: Error {
        case notFound
    }

    init() {
        let player = AVPlayer()
        videoMaterial = VideoMaterial(avPlayer: player)
        self.player = player
    }
    func loadVideo(named name: String) throws {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
            // In case video was playing, stop it
            throw VideoError.notFound
        }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

//        // Remove old observer if needed
        NotificationCenter.default.removeObserver(self)

        // Add observer to loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.player.seek(to: .zero)
            self.player.play()
        }
        player.play()
    }

    // Stop playing
    func stop() {
            player.pause()
        }
    
    // Reset to beginning
    func reset() {
        player.seek(to: .zero)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
