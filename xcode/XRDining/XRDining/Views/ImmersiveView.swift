//
//  ImmersiveView.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import OSLog

struct ImmersiveView: View {
    
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        @Bindable var appModel = appModel
        
        RealityView { content in
            content.add(appModel.setupContentEntity())
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
                ModelComponent(mesh: .generateSphere(radius: 45),
                               materials: [videoMaterial])
            )
            entity.scale *= .init(x:-1, y:1, z:1)
            let rotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
            entity.orientation = rotation * entity.orientation
            if !appModel.isSingleUser {
                //entity.position =  SIMD3<Float>(0, -0.5, 35)
                entity.position = SIMD3<Float>(0, -appModel.seatHeightOffset, appModel.screen2tableDistance + 10.0)
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
@MainActor
let logger = Logger(subsystem: "com.biteplanet.XRDining", category: "general")

