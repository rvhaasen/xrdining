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
            }
        }
        .frame(depth: 0)
    }
    
    func updatePodiumPose(_ phraseDeckPodium: Entity) {
        //let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
//        phraseDeckPodium.position = .init(podiumPosition)
        phraseDeckPodium.position = .init(Vector3D(x: 0.0, y: 1.5, z: appModel.screen2tableDistance+0.5))
    }
}
