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
import GroupActivities

struct ImmersiveView: View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(AppModel.self) var appModel
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var count = 0
    @State private var video = VideoTextureController()
    
    @State private var scene = SceneRef()
    
    let audio = AudioManager()
    
    let menuTags = ["a", "b", "c"]

    //@State private var labels: [String] = []         // what we want to add
    @State private var inserted = Set<String>()      // which ones are in the scene

    
    var body: some View {
        @Bindable var appModel = appModel

        var it = appModel.items.makeIterator()
        //var currentItem = it.next() as StageItem?
        var nextStageAt: Int = 0
        
        var closing = false
        
        RealityView { content, attachments  in
                        
//            // Add menu objects
//            for tag in appModel.items.map(\.title) {
//                attachments.entity(for: tag).map(content.add)
//            }
//
//            // Set the rotation such that the menu faces the user (caller/callee)
//            for tag in appModel.items.map(\.title) {
//                attachments.entity(for: tag).map(updatePodiumPose(_:))
//            }
//            if appModel.isSingleUser {
//                Task {
//                    dismissWindow(id: "MainWindow")
//                }
//            }
            logInfo("In open closure of ImmersiveView")
            appModel.sessionController?.updateLocalParticipantRole()
            content.add(appModel.setupContentEntity())
            
            // Create placeholder material, it will be replaced by VideoMaterial when video is loaded
            let mat  = SimpleMaterial(color: .black, isMetallic: false)
            appModel.mySphere = ModelEntity( mesh: .generateSphere(radius: 45),
                                             materials: [mat])
            
            appModel.mySphere.name = "sphere"
            
            appModel.mySphere.scale *= .init(x:-1, y:1, z:1)
                        
            if !appModel.isSingleUser {
                //entity.position =  SIMD3<Float>(0, -0.5, 35)
                // +10 is specific for visvijver scene, in order to put the users
                // not "in the water" for others this is not needed
                let rotation2 = simd_quatf(angle: -.pi/2.0, axis: [0, 1, 0])
                appModel.mySphere.transform.rotation = rotation2
                appModel.mySphere.position = SIMD3<Float>(0, -appModel.seatHeightOffset, appModel.screen2tableDistance)

                // appModel.mySphere.position = SIMD3<Float>(0, -appModel.seatHeightOffset, appModel.screen2tableDistance + 10.0)

                //                let rotation2 = simd_quatf(angle: Float(appModel.sphereAngle) * 2.0 * .pi/360.0, axis: [0, 1, 0])
                //                foundEntity.transform.rotation = rotation2
            }
            
            content.add(appModel.mySphere)
            
            let root = Entity()
            root.name = "root"
            content.add(root)
            scene.root = root
            logInfo("Leaving open closure of ImmersiveView")
        }
        update: { content, attachments in
            
            guard let root = scene.root else { return }
            guard appModel.immersiveSpaceState == .open else { return }
            
            // Insert any labels that aren't in the scene yet
            for id in appModel.activeAttachments where !inserted.contains(id) {
                if let e = attachments.entity(for: "\(id)") {
                    // Set the name of the entity so it can be found when it needs to be removed
                    e.name = id
                    root.addChild(e)
                    appModel.insertedAttachments.insert(id)
                    attachments.entity(for: id).map(updatePodiumPose(_:))
                }
            }

            // Remove entities for labels that were deleted
            for gone in appModel.insertedAttachments.subtracting(appModel.activeAttachments) {
                if let child = root.children.first(where: { $0.name == "\(gone)" }) {
                    child.removeFromParent()
                }
                appModel.insertedAttachments.remove(gone)
            }
            
//            logger.info("SPHERE rotate in to \(appModel.sphereAngle)")
            if let foundEntity = content.entities.first(where: { $0.name == "sphere" }) {
                // Use foundEntity
                foundEntity.transform.translation = [0,0, Float(appModel.screen2tableDistance)]
            }
        }
        attachments: {
            ForEach(appModel.items.filter { $0.pdfURL != nil && !$0.modelFromBundle.isEmpty} ) { item in
                Attachment(id: item.title) {
                    CourseView(url: item.pdfURL!, modelName: "gebakske")
                    //                    .glassBackgroundEffect(      // ✅ gives you the translucent visionOS glass
                    //                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    //                    )
                        .frame(width: 800, height: 1400)
//                        .frame(width: 450, height: 700)
                }
            }
        }
        .onReceive(timer) { time in
            logInfo("Time, ticked, count is now \(count), nextStage is \(nextStageAt)")
            defer {
                count += 1
            }
            if (count == nextStageAt) {
                logInfo("Count reached to next stage: \(nextStageAt)")
                if let item = it.next() as StageItem? {
                    
                    guard item.isEnabled else {
                        audio.stop()
                        
                        // ffwd to next scene
                        nextStageAt += 1
                        return
                    }
                    nextStageAt += item.duration
                    logInfo("Duration for next video is \(item.duration) seconds")
                    appModel.sphereAngle = Double(item.rotation)
                    logInfo("Next stage at \(nextStageAt)")
                    
                    if let audioURL = item.audioURL {
                        audio.playSound(url: audioURL)
                    }
                    else {
                        // Stop currently playing audio
                        audio.stop()
                    }
                    logInfo("Running next video...")
                    
                    if let url = item.videoURL {
                        startVideo(url: url, volume: item.volume)
                    }
                    // Select course as activeAttachements if defined in stage
                    if item.pdfURL != nil {
                        logInfo("Enabling attachement \(item.title)")
                        appModel.activeAttachments = [item.title]
                    }
                    else {
                        logInfo("No attachment for this stage, clearing activeAttachments")
                        appModel.activeAttachments = []
                    }
                } else {
                    // Last stage has been processed, stop all, close views which puts the
                    // application to background
                    appModel.immersiveSpaceState = .inTransition
                    
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
        .onAppear {
            Task {
                logInfo("Wait for reference object to be loaded...")
                let ro = try? await waitForEnabledReferenceObjects(timeout: .seconds(10))
                guard let ro, ro.count == appModel.nrOfReferenceObjects else {
                    logInfo("No reference objects available (timeout or cancelled). Skipping object tracking.")
                    return
                }
                logInfo("Reference objects loaded")
                await appModel.runARKitSession()
                logInfo("ARKit session started")
                
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

            stopVideo()
            logInfo("Done, exiting immersive space")
            audio.stop()

            if let session = appModel.currentGroupSession {
                session.end()
                logInfo("Ended shareplay session")
            }
            appModel.currentGroupSession = nil
            dismissWindow(id: "MainWindow")

            appModel.didLeaveImmersiveSpace()
        }
        
        // Trick to redraw the RealityView when
        // a different video file is selected
        //.id(appModel.selectedWorld)
    }
    
    func startVideo( url: URL?, volume: Float) {
        guard let url else {
            logInfo("Cannot play video")
            return
        }
        Task { await swapVideoFromUrl(on: appModel.mySphere, materialIndex: 0, to: url, volume: volume) }
    }
    func stopVideo() {
        if let model = appModel.mySphere.model,
           model.materials.indices.contains(0),
           let videoMaterial = model.materials[0] as? VideoMaterial {
            if let player = videoMaterial.avPlayer {
                player.pause()
            }
            else {
                logInfo("Cannot stop videoplayer, no player found")
            }
        }
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
        
        var position: SIMD3<Float>
        var angle: Float
        
        if appModel.isSingleUser {
            // TODO refactor to table-width/2 or something like that
            position = .init(Vector3D(x: -0.5 , y: 1.0, z: appModel.screen2tableDistance-0.5))
            angle = .pi / 4
        } else {
            position = .init(Vector3D(x: 0, y: 1.0, z: appModel.screen2tableDistance-0.5))
            angle = appModel.spatialTemplateRole == DiningTemplate.Role.caller ? -.pi / 4 : .pi / 4
            // RH
            angle=0
        }
        entity.position = position
        entity.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
    }
    struct ReferenceObjectsTimeoutError: Error {}

    @MainActor
    func waitForEnabledReferenceObjects(timeout: Duration? = .seconds(5)) async throws -> [ReferenceObject] {
        let clock = ContinuousClock()
        let start = clock.now

        while true {
            let refs = appModel.objectTracking.referenceObjectLoader.enabledReferenceObjects
            if refs.count == 2 {
                return refs
            }
            try Task.checkCancellation()
            if let timeout, clock.now - start > timeout {
                throw ReferenceObjectsTimeoutError()
            }
            try await Task.sleep(for: .milliseconds(100))
        }
    }
}
@Observable
final class SceneRef {
    weak var root: Entity?
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
