//
//  AppModel.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import Foundation
import SwiftUI
import Observation
import ARKit
import RealityKit
internal import os

/// Maintains app-wide state

@Observable @MainActor
class AppModel {
    
    private let session = ARKitSession()
    private let imageTracking = ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "ARImages"))
    
    var imageAnchors = [UUID: ImageAnchor]()
    var entityMap = [UUID: Entity]()
    
    let contentRoot = Entity()
    
    var imageWidth: Float = 0
    var imageHeight: Float = 0
    var sessionController: SessionController?

    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum World: CustomStringConvertible, CaseIterable, Identifiable {
        case visvijver,lanciaDag,none
        var id: Self { self }
        
        var description: String {
            switch self {
                case .visvijver: return "philips-visvijver"
                case .lanciaDag: return "lancia_dag_360"
                case .none: return "none"
            }
        }
    }
    enum ErrorState: Equatable {
        case noError
        case providerNotSupported
        case providerNotAuthorized
        case sessionError(ARKitSession.Error)
        
        static func == (lhs: AppModel.ErrorState, rhs: AppModel.ErrorState) -> Bool {
            switch (lhs, rhs) {
            case (.noError, .noError): return true
            case (.providerNotSupported, .providerNotSupported): return true
            case (.providerNotAuthorized, .providerNotAuthorized): return true
            case (.sessionError(let lhsError), .sessionError(let rhsError)): return lhsError.code == rhsError.code
            default: return false
            }
        }
    }
    var selectedWorld: World
    
    var isSingleUser: Bool = false
    var doObjectDetection: Bool = false
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var skyBox: Entity? = nil
    
    var videoModel: VideoModel?
    
    var sphereCenter = SIMD3<Float>(0, -0.5, 30)
    
    // When a person denies authorization or a data provider state changes to an error condition,
    // the main window displays an error message based on the `errorState`.
    var errorState: ErrorState = .noError
    
 
    private var areAllDataProvidersSupported: Bool {
        if isSimulator {
            return true
        } else {
            return ImageTrackingProvider.isSupported && PlaneDetectionProvider.isSupported
        }
    }
    
    func areAllDataProvidersAuthorized() async -> Bool {
        // It's sufficient to check that the authorization status isn't 'denied'.
        // If it's `notdetermined`, ARKit presents a permission pop-up menu that appears as soon
        // as the session runs.
        let authorization = await ARKitSession().queryAuthorization(for: [.worldSensing])
        return authorization[.worldSensing] != .denied
    }
    /// Responds to events such as authorization revocation.
    func monitorSessionUpdates() async {
        for await event in session.events {
            logger.info("\(event.description)")
            switch event {
            case .authorizationChanged(type: _, status: let status):
                logger.info("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = .providerNotAuthorized
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                logger.info("Data providers state changed: \(providers), \(state)")
                if let error {
                    logger.error("Data provider reached an error state: \(error)")
                    errorState = .sessionError(error)
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
    
    func runSession() async {
        do {
            try await session.run([imageTracking])
        } catch {
            guard error is ARKitSession.Error else {
                preconditionFailure("Unexpected error \(error).")
            }
            // Session errors are handled in AppModel.monitorSessionUpdates().
        }
    }
    func processImageTrackingUpdates() async {
        for await update in imageTracking.anchorUpdates {
            let imageAnchor = update.anchor
            switch update.event {
            case .added:
                logger.info("[TRACKING] New image anchor added.")
                createImage(imageAnchor)
            case .updated:
                //logger.info("[TRACKING] image anchor updated.")
                updateImage(imageAnchor)
            case .removed:
                logger.info("[TRACKING] image anchor removed")
                removeImage(imageAnchor)
            }
        }
    }
    func createImage(_ anchor: ImageAnchor) {
        logger.info("Creating image")
        if imageAnchors[anchor.id] == nil {
            // Add a new entity to represent this image.
            let scaleFactor = anchor.estimatedScaleFactor
            let imagePhysicalSize = anchor.referenceImage.physicalSize
            let width = Float(imagePhysicalSize.width) * scaleFactor
            imageWidth = width
            let height = Float(imagePhysicalSize.height) * scaleFactor
            imageHeight = height
            let imageName = anchor.referenceImage.name ?? "Unknown Image"
            logger.info("Image \(imageName) added")
            let quad = MeshResource.generatePlane(width: width, height: height)
            
            let entity = ModelEntity(mesh: quad, materials: [OcclusionMaterial()])
//            let entity = ModelEntity(mesh: quad, materials: [UnlitMaterial(color: .green)])
            //entity.components.set(PortalComponent(target: portalWorld,
            //                                      clippingMode: .plane(.positiveZ),
            //                                      crossingMode: .plane(.positiveZ)))
            
            entityMap[anchor.id] = entity
            contentRoot.addChild(entity)
            imageAnchors[anchor.id] = anchor
            
            //await createPortalOpeningAnimationEntity(portalQuadEntity: entity)
        }
        
        if anchor.isTracked {
            var transform = Transform(matrix: anchor.originFromAnchorTransform)
            let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Align entity to Poster
            transform.rotation = transform.rotation * rotationX
            entityMap[anchor.id]?.transform = transform
            
            //setRobotPositionAndOrientation(imageAnchor: anchor)
            
            //createPlatformForRobot()
        }
    }
    func updateImage(_ anchor: ImageAnchor) {
        if anchor.isTracked {
            var transform = Transform(matrix: anchor.originFromAnchorTransform)
            let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Align entity to Poster
            transform.rotation = transform.rotation * rotationX
            entityMap[anchor.id]?.transform = transform
            imageAnchors[anchor.id] = anchor
            
        }
    }
    
    func removeImage(_ anchor: ImageAnchor) {
        entityMap[anchor.id]?.removeFromParent()
        entityMap[anchor.id] = nil
        imageAnchors[anchor.id] = nil
    }

    // Constructor
    init() {
        
        videoModel = VideoModel()
        self.selectedWorld = .visvijver
        if !isSimulator {
            runBackgroundTasks()
        }
    }
    let isSimulator: Bool = {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }()
    
    func runBackgroundTasks() {
        if !areAllDataProvidersSupported {
            errorState = .providerNotSupported
        }
        Task {
            if await !areAllDataProvidersAuthorized() {
                errorState = .providerNotAuthorized
            }
        }
        Task {
            await monitorSessionUpdates()
        }
        Task {
            await runSession()
        }
        Task {
            await processImageTrackingUpdates()
        }
    }
    func setupContentEntity() -> Entity {
        return contentRoot
    }
}
