//
//  VideoTextureController.swift
//  XRDining
//
//  Created by Rick van Haasen on 30/08/2025.
//
import SwiftUI
import RealityKit
import AVFoundation

@Observable
@MainActor
final class VideoTextureController {
    // Keep these strongly referenced
    private(set) var player = AVPlayer()
    private var currentMaterial: VideoMaterial?
    private var modelEntity: ModelEntity?

    func attach(to entity: ModelEntity) {
        self.modelEntity = entity
    }
    
    // Prepare an AVPlayerItem off the main thread and ensure it's playable
    func prepareItem(videoName: String) async throws -> AVPlayerItem {
        
//        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
//            // In case video was playing, stop it
//            print("Could not load video \(videoName)")
//            return nil
//        }
        let url = Bundle.main.url(forResource: videoName, withExtension: "mp4")!

        let asset = AVURLAsset(url: url)
        // Modern async property loading (iOS 15+ / visionOS):
        let playable = try await asset.load(.isPlayable)
        guard playable else { throw NSError(domain: "Video", code: -1, userInfo: [NSLocalizedDescriptionKey: "Asset not playable"]) }
        return AVPlayerItem(asset: asset)
    }

    func start(with videoName: String) async {
        do {
            let item = try await prepareItem(videoName: videoName)
            player.replaceCurrentItem(with: item)
            let mat = try VideoMaterial(avPlayer: player)
            currentMaterial = mat
            apply(material: mat)
            player.play()
        } catch {
            print("Failed to start video: \(error)")
        }
    }

    /// Safe switch to another file
    func switchTo(videoName: String) async {
        // 1) Preload next item off main thread
        let nextItem: AVPlayerItem
        do {
            nextItem = try await prepareItem(videoName: videoName)
        } catch {
            print("Failed to prepare next item: \(error)")
            return
        }

        // 2) Pause to avoid mid-frame retargeting
        player.pause()

        // 3a) Option A: swap the entire material (most robust)
        do {
            // Use a *new* AVPlayer for the new material if you want truly independent pipelines
            // to avoid any internal churn from replaceCurrentItem:
            let freshPlayer = AVPlayer()
            freshPlayer.replaceCurrentItem(with: nextItem)

            let newMat = try VideoMaterial(avPlayer: freshPlayer)

            // Apply atomically on the main actor
            apply(material: newMat)

            // Keep references alive
            self.player = freshPlayer
            self.currentMaterial = newMat

            // 4) Start playback
            freshPlayer.play()
        } catch {
            print("Failed to create/apply new VideoMaterial: \(error)")
            // Fallback 3b) Option B: reuse the same player; this works too, but swap after pause
            player.replaceCurrentItem(with: nextItem)
            player.play()
        }

        // 5) Optionally, delay releasing old objects by one runloop to avoid dealloc during render
        // (Not strictly necessary here because we kept strong refs, but useful if you keep
        // multiple materials/players.)
        DispatchQueue.main.async { /* no-op; ensures previous frame fully presented */ }
    }

    private func apply(material: VideoMaterial) {
        guard var model = modelEntity?.model else { return }
        // Replace the first material (or choose the correct index)
        if !model.materials.isEmpty {
            model.materials[0] = material
        } else {
            model.materials = [material]
        }
        modelEntity?.model = model
    }
}

