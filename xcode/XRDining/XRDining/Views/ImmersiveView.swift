//
//  ImmersiveView.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI
import RealityKit
import ARKit
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
            //let entity = Entity()
            guard let videoMaterial = appModel.videoModel?.videoMaterial else {
                return
            }
            let mySphere = ModelEntity( mesh: .generateSphere(radius: 45),
                materials: [videoMaterial])
            mySphere.name = "sphere"

            //entity.components.set(
            //    ModelComponent(mesh: .generateSphere(radius: 45),
            //                   materials: [videoMaterial])
            //)
            //entity.name = "sphere"
            mySphere.scale *= .init(x:-1, y:1, z:1)
            //let rotation = simd_quatf(angle: -.pi, axis: [0, 1, 0])
            //mySphere.orientation = rotation * mySphere.orientation
            if !appModel.isSingleUser {
                //entity.position =  SIMD3<Float>(0, -0.5, 35)
                mySphere.position = SIMD3<Float>(0, -appModel.seatHeightOffset, appModel.screen2tableDistance + 10.0)
            }
            content.add(mySphere)
//            let attachment = ViewAttachmentComponent(
//                rootView: CarouselView()
//            )
//            let koekjes = Entity(components: attachment)
//            koekjes.position = SIMD3<Float>(0, 0, -0.1)
//            content.add(koekjes)
             
        } update: { content in
            
//            for entity in content.entities {
//                // Do something with each entity
//                logger.info("UPDATE closure: Entity name: \(entity.name)")
//            }
//            logger.info("Now recursive:")
//            for root in content.entities {
//                visitAllEntities(root) { entity in
//                    logger.info("Entity name: \(entity.name)")
//                }
//            }
            let _ = appModel.sphereAngle
            logger.info("SPHERE rotate in to \(appModel.sphereAngle)")
//            if let rootEntity = content.entities.first,
//               let mySphere = rootEntity.findEntity(named: "sphere") as? ModelEntity {
//                logger.info("SPHERE object found")
//                mySphere.transform.rotation = simd_quatf(angle: Float(appModel.sphereAngle), axis: [1, 0, 0])
//            }
            if let foundEntity = content.entities.first(where: { $0.name == "sphere" }) {
                // Use foundEntity
                logger.info("SPHERE object found")
                let rotation1 = simd_quatf(angle: Float(appModel.sphereAngle/360 * 2 * .pi), axis: [0, 0, 1])
                let angle = appModel.videos[appModel.selectedWorld]?.rotationDegrees ?? 0
                //print(angle)
                //angle = Float(-90)
                let rotation2 = simd_quatf(angle: angle * 2.0 * .pi/360.0, axis: [0, 1, 0])
                foundEntity.transform.rotation = rotation1 * rotation2
            }
                
//            if let mySphere = content.entities.first.findEntity(named: "sphere") {
//                logger.info("SPHERE object found")
//                mySphere.transform.rotation = simd_quatf(angle: Float(appModel.sphereAngle), axis: [1, 0, 0])
//            }
        }
        .onAppear {
            Task {
                await appModel.runARKitSession()
                
                // Wait for object anchor updates and maintain a dictionary of visualizations
                // that are attached to those anchors.
                for await anchorUpdate in appModel.objectTrackingProvider!.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    
                    switch anchorUpdate.event {
                    case .added:
                        // Create a new visualization for the reference object that ARKit just detected.
                        // The app displays the USDZ file that the reference object was trained on as
                        // a wireframe on top of the real-world object, if the .referenceobject file contains
                        // that USDZ file. If the original USDZ isn't available, the app displays a bounding box instead.
                        let model = appModel.objectTracking.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model, withState: appModel.self)
                        //visualization.entity.components.set(visibleObjectsGroup)
                        appModel.objectVisualizations[id] = visualization
                        appModel.contentRoot.addChild(visualization.entity)
                        logInfo("TRACKING added \(anchor.referenceObject.name)")
                    case .updated:
                        //logger.info("TRACKING updated \(anchor.referenceObject.name)")
                        appModel.objectVisualizations[id]?.update(with: anchor)
                    case .removed:
                        appModel.objectVisualizations[id]?.entity.removeFromParent()
                        appModel.objectVisualizations.removeValue(forKey: id)
                        logInfo("TRACKING removed \(anchor.referenceObject.name)")
                    }
                }
            }
        }
        .onDisappear() {
            logInfo("Leaving immersive space.")
            appModel.arkitSession.stop()
            
            for (_, visualization) in appModel.objectVisualizations {
                appModel.setupContentEntity().removeChild(visualization.entity)
            }
            appModel.objectVisualizations.removeAll()
            logInfo("Removed object visualizations.")

            appModel.didLeaveImmersiveSpace()
        }
        // Trick to redraw the RealityView when
        // a different video file is selected
        //.id(appModel.selectedWorld)
    }
    func visitAllEntities(_ entity: Entity, action: (Entity) -> Void) {
        action(entity)
        for child in entity.children {
            visitAllEntities(child, action: action)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}


