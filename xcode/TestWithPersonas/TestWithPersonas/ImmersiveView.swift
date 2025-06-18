//
//  ImmersiveView.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct ImmersiveView: View {

    @Environment(AppModel.self) var appModel
    var body: some View {
        //let videoURL = Bundle.main.url(forResource: "lancia_dag_360", withExtension: "mp4")!
        let videoURL = Bundle.main.url(forResource: "philips-visvijver", withExtension: "mp4")!
        let player = AVPlayer(url: videoURL)
        let videoMaterial = VideoMaterial(avPlayer: player)

        RealityView { content in
            player.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            //content.add(root)
            if let skyBox = appModel.skyBox {
                if var modelComponent = skyBox.components[ModelComponent.self] {
                    modelComponent.materials = [videoMaterial]
                    
                    // Set the component back
                    skyBox.components.set(modelComponent)
                }
                content.add(skyBox)
                player.play()
            }
  
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
}

//#Preview(immersionStyle: .mixed) {
//    ImmersiveView()
//        .environment(AppModel())
//}
