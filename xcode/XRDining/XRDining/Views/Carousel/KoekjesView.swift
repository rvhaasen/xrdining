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
    
    let menuTags = ["menu-starter", "menu-main", "menu-dessert"]

    var body: some View {
        RealityView { content, attachments  in
            for tag in menuTags {
                attachments.entity(for: tag).map(content.add)
            }
        } update: { content, attachments in
            for tag in menuTags {
                attachments.entity(for: tag).map(updatePodiumPose(_:))
            }
//            attachments.entity(for: "PhraseDeckView")?.isEnabled = false
        } attachments: {
            ForEach(menuTags, id: \.self) { tag in
                Attachment(id: tag) {
                    CarouselView(url: Bundle.main.url(forResource: "factuur", withExtension: "pdf")!)
                    .glassBackgroundEffect(      // ✅ gives you the translucent visionOS glass
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
            }
        }
        //.frame(depth: 0)
    }
    
    // When using in shareplay, the main-screen defines the reference coordinate-system
    // Personas are positioned according to the spatial templates which also uses the
    // main windows as reference. Hence in order to position the menu such that it is
    // visible for the users, it should consider the spatial template to position and
    // orient the menu-view
    //
    func updatePodiumPose(_ entity: Entity) {
//      let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
//      phraseDeckPodium.position = .init(podiumPosition)
        entity.position = .init(Vector3D(x: 0.0, y: 1.5, z: appModel.screen2tableDistance-0.5))
        entity.orientation = simd_quatf(angle: -.pi / 4, axis: SIMD3<Float>(0, 1, 0))
    }
}

