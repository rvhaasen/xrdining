//
//  KoekjesView.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/08/2025.
//
import RealityKit
import Spatial
import SwiftUI

struct KoekjesView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        RealityView { content, attachments  in
            attachments.entity(for: "PhraseDeckView").map(content.add)
        } update: { content, _ in
            content.entities.first.map(updatePodiumPose(_:))
        } attachments: {
            Attachment(id: "PhraseDeckView") {
                CarouselView()
                    .glassBackgroundEffect(      // ✅ gives you the translucent visionOS glass
                      in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
            }
        }
        .frame(depth: 0)
    }
    
    func updatePodiumPose(_ carousel: Entity) {
        //let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
//        phraseDeckPodium.position = .init(podiumPosition)
        carousel.position = .init(Vector3D(x: 0.0, y: 1.5, z: appModel.screen2tableDistance-0.5))
        carousel.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0))
    }
}

