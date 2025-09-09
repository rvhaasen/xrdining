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
internal import Combine

struct ImmersiveView: View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(AppModel.self) var appModel
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var count = 0
    @State private var video = VideoTextureController()
    
    let audio = AudioManager()
    
    let menuTags = ["menu-starter", "menu-main", "menu-dessert"]
    
    var body: some View {
        @Bindable var appModel = appModel
        
        RealityView { content, attachments  in
            
            for tag in menuTags {
                attachments.entity(for: tag).map(content.add)
            }
            for tag in menuTags {
                attachments.entity(for: tag).map(updatePodiumPose(_:))
            }
            content.add(appModel.setupContentEntity())
            // Create placeholder material, it will be replaced by VideoMaterial when video is loaded
            let mat  = SimpleMaterial(color: .black, isMetallic: false)
            appModel.mySphere = ModelEntity( mesh: .generateSphere(radius: 45),
                                             materials: [mat])
            
            appModel.mySphere.name = "sphere"
            
            //            Task { await swapVideo(on: appModel.mySphere, materialIndex: 0, to: "domburg_duinen") }
            
            appModel.mySphere.scale *= .init(x:-1, y:1, z:1)
            
            //            let rotation = simd_quatf(angle: -.pi, axis: [0, 1, 0])
            //            appModel.mySphere.orientation = rotation * appModel.mySphere.orientation
            
            if !appModel.isSingleUser {
                //entity.position =  SIMD3<Float>(0, -0.5, 35)
                // +10 is specific for visvijver scene, in order to put the users
                // not "in the water" for others this is not needed
                appModel.mySphere.position = SIMD3<Float>(0, -appModel.seatHeightOffset, appModel.screen2tableDistance + 10.0)
            }
            
            content.add(appModel.mySphere)

            //            audio.playSound(named: "nordsea_with_gulls", fileExtension: "mp3")
            
        }
        update: { content, attachments in
            
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
            if let foundEntity = content.entities.first(where: { $0.name == "sphere" }) {
                // Use foundEntity
                logger.info("SPHERE object found")
                let rotation1 = simd_quatf(angle: Float(appModel.sphereAngle/360 * 2 * .pi), axis: [0, 0, 1])
                let angle = appModel.videos[appModel.selectedWorld]?.rotationDegrees ?? 0
                //print(angle)
                let rotation2 = simd_quatf(angle: angle * 2.0 * .pi/360.0, axis: [0, 1, 0])
                //                foundEntity.transform.rotation = rotation1 * rotation2
                foundEntity.transform.rotation = rotation2
                //let rotation2 = simd_quatf(angle: angle * 2.0 * .pi/360.0, axis: [0, 1, 0])
                foundEntity.transform.translation = [0,0,Float(appModel.sphereAngle)]
            }
        }
        attachments: {
            ForEach(menuTags, id: \.self) { tag in
                Attachment(id: tag) {
                    //CarouselView(url: Bundle.main.url(forResource: "factuur", withExtension: "pdf")!)
                    CourseView(pdf: "factuur", modelName: "gebakske")
//                    .glassBackgroundEffect(      // ✅ gives you the translucent visionOS glass
//                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
//                    )
                    .frame(width: 300, height: 600)
                }
            }
        }
        .onReceive(timer) { time in
            print("Time, ticked, count is now \(count)")
            
            var videoFile = ""
            var audioFile = ""
            var audioFileExtension = ""
            
            // State machine for demo
            switch(count) {
            case 0:
                videoFile = "valkenburg_geul_10s_topaz"
                //videoFile = "visvijver_qoocam_8k30_8k_topaz"

            case 10:
                
                //appModel.videoModel?.stop()
//                appModel.immersiveSpaceState = .inTransition
//                Task {
//                    await dismissImmersiveSpace()
//                }
//                dismissWindow(id: "MainWindow")

                //videoFile = "lancia_dag_360"
                videoFile = "valkenburg_rand_10s_topaz"
//                audioFile = "xrdining-main-meal"
                //audioFile = "nordsea_with_gulls"
                //audioFileExtension = "mp3"
                //audio.playSound(named: "nordsea_with_gulls", fileExtension: "mp3")
            case 21:
//                videoFile = "visvijver_qoocam_8k30_8k_topaz"
//                audioFile = "xrdining-desert"
//                audioFileExtension = "m4a"
                
                videoFile = "friesland_10s_topaz"
//                audioFile = "xrdining-main-meal"
                //audioFile = "soft-wind"
                //audioFileExtension = "mp3"
            
//            case 15:
//                videoFile = "domburg_strand_topaz"
//                audioFile = "nordsea_with_gulls"
//                audioFileExtension = "mp3"
//
//            case 20:
//                videoFile = "domburg_duinen_bos_topaz"
//                audioFile = "nordsea_with_gulls"
//                audioFileExtension = "mp3"

            case 400:
                //appModel.videoModel?.stop()
                appModel.immersiveSpaceState = .inTransition
                Task {
                    await dismissImmersiveSpace()
                    dismissWindow(id: "MainWindow")
                }
            default:
                videoFile = ""
                audioFile = ""
            }
            if (!videoFile.isEmpty ) {
//                do {
//                    appModel.videoModel?.stop()
//                    try appModel.videoModel?.loadVideo(named: videoFile)
//                } catch {
//                    print("Could not load video file")
//                }
                Task { await swapVideo(on: appModel.mySphere, materialIndex: 0, to: videoFile) }
                
                // Alternative to be tried if there still is
                // a race condition:
//                await MainActor.run { video.attach(to: entity) }
//                Task { await video.start(with: Bundle.main.url(forResource: "intro", withExtension: "mp4")!) }
                
                
            }
            audio.stop()
            
//            if (!audioFile.isEmpty) {
//                audio.playSound(named: audioFile, fileExtension: audioFileExtension)
//            }
            count += 1
        }
        .onAppear {
            Task {
                await appModel.runARKitSession()
                
                // Wait for object anchor updates and maintain a dictionary of visualizations
                // that are attached to those anchors.
                if let objectTrackingProvider = appModel.objectTrackingProvider {
                    for await anchorUpdate in objectTrackingProvider.anchorUpdates {
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
    // When using in shareplay, the main-screen defines the reference coordinate-system
    // Personas are positioned according to the spatial templates which also uses the
    // main windows as reference. Hence in order to position the menu such that it is
    // visible for the users, it should consider the spatial template to position and
    // orient the menu-view
    //
    func updatePodiumPose(_ entity: Entity) {
        entity.position = .init(Vector3D(x: 0.0, y: 1.5, z: appModel.screen2tableDistance-0.5))
        let angle : Float = appModel.spatialTemplateRole == .caller ? -.pi / 4 : .pi / 4
        entity.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
