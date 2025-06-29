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
        @Bindable var appModel = appModel
        
        RealityView { content in
            do {
                try appModel.videoModel?.loadVideo(named: appModel.selectedWorld.description)
            } catch {
                print("Could not load video file \"\(appModel.selectedWorld.description).mp4\"")
                return
            }
            let entity = Entity()
            guard let videoMaterial = appModel.videoModel?.videoMaterial else {
                return
            }
            entity.components.set(
                ModelComponent(mesh: .generateSphere(radius: 30),
                               materials: [videoMaterial])
            )
            entity.scale *= .init(x:-1, y:1, z:1)
            let rotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
            entity.orientation = rotation * entity.orientation
            if !appModel.isSingleUser {
                entity.position = appModel.sphereCenter
            }
            content.add(entity)
        }
        // Trick to redraw the RealityView when
        .id(appModel.selectedWorld)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}

