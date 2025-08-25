//
//  AudioManager.swift
//  XRDining
//
//  Created by Rick van Haasen on 19/08/2025.
//
import AVFoundation

class AudioManager {
    private var player: AVAudioPlayer?

    func playSound(named filename: String, fileExtension: String = "m4a") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Could not find \(filename).\(fileExtension)")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            player?.volume = 1.0
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    func stop() {
        
    }
}
