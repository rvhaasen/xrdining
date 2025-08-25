//
//  VideoTextureSwitcher.swift
//  XRDining
//
//  Created by Rick van Haasen on 23/08/2025.
//

import AVFoundation
import RealityKit

func makePlayer(url: URL, loop: Bool = true) async -> AVPlayer {
    let asset = AVURLAsset(url: url)
    _ = try? await asset.load(.isPlayable)   // warm up
    let item = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: item)
    player.actionAtItemEnd = .none
    if loop {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero); player?.play()
        }
    }
    return player
}

@MainActor
//func swapVideo(on entity: ModelEntity, materialIndex: Int, to url: URL) async {
func swapVideo(on entity: ModelEntity, materialIndex: Int, to videoName: String) async {

    guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
        // In case video was playing, stop it
        print("Could not load video \(videoName)")
        return
    }
    guard var model = entity.model,
          model.materials.indices.contains(materialIndex) else { return }

    let player = await makePlayer(url: url, loop: true)

    // Rebuild the material with the new player
    var mats = model.materials
    if var vm = mats[materialIndex] as? VideoMaterial {
        vm.avPlayer = player            // update player
        mats[materialIndex] = vm        // replace entry (value-type)
    } else {
        mats[materialIndex] = VideoMaterial(avPlayer: player)
    }

    model.materials = mats
    entity.model = model               // assign back to trigger update
    player.play()
}
