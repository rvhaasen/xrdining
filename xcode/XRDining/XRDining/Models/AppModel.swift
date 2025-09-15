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
import OSLog

/// Maintains app-wide state

@Observable @MainActor
class AppModel {
    
    // Definition of scenes
    var items: [StageItem] = []
    
    // List of attachments (used for course-description)
    var activeAttachments: [String] = []
    var insertedAttachments: Set<String> = Set<String>()

    // Set default role to called,
    // For the initiator of it will be set to 'called'
    // This will define the seating positions
    var spatialTemplateRole = DiningTemplate.Role.called
    
    let developerMode = true
    let arkitSession = ARKitSession()
    
    private var sessionTask: Task<Void, Never>?
    
    // Configure he image tracking provider
    private let imageTracking = ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "ARImages"))

    // Image anchors and their corresponding entities
    var imageAnchors = [UUID: ImageAnchor]()
    var entityMap = [UUID: Entity]()
    
    var mySphere: ModelEntity = ModelEntity()
    
    // TODO: these 2 are most likely not needed, remove them
    var imageWidth: Float = 0
    var imageHeight: Float = 0
    
    var sphereAngle: Double = 0.0
    var positionOffset: Double = 0.0

    // Detected images will create an entity that  detected images that will be added to contentRoot. For removing .removeFromParent is used on the particular entity. During setup of the reality-view the contentRoot is added to the scene.
    let contentRoot = Entity()

    // The object tracking provider cannot be configured yet, for this the Reference object first have to be loaded.
    var objectTrackingProvider: ObjectTrackingProvider?
    
    var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    
    var sessionController: SessionController?

    let immersiveSpaceID = "ImmersiveSpace"
    
    let objectTracking = ObjectTrackingModel()
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum World: CustomStringConvertible, CaseIterable, Identifiable {
        case
            visvijver,
            visvijver_qoocam_topaz,
            lanciaDag,none
        var id: Self { self }
        
        var description: String {
            switch self {
                case .visvijver_qoocam_topaz: return "visvijver_qoocam_8k30_8k_topaz"
                case .visvijver: return "philips-visvijver"
                case .lanciaDag: return "lancia_dag_360"
                case .none: return "none"
            }
        }
    }
    var selectedWorld: VideoInfo.World

    var videos = [VideoInfo.World: VideoInfo]()
        
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
    
    var isSingleUser: Bool = true
    var doObjectDetection: Bool = false
    
    var immersiveSpaceState : ImmersiveSpaceState = .closed
    
    var skyBox: Entity? = nil
    
    var videoModel: VideoModel?
    
    // TODO: refactor in order to make it content dependent,
    // e.g. current value of 0.5 was for the "philips visvijver" video
    var screen2tableDistance: Float = 0.0
    let seatHeightOffset: Float = 0.5
        
    // When a person denies authorization or a data provider state changes to an error condition,
    // the main window displays an error message based on the `errorState`.
    var errorState: ErrorState = .noError
    
    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    var areAllDataProvidersSupported: Bool {
        if isSimulator {
            return true
        } else {
            return ImageTrackingProvider.isSupported && PlaneDetectionProvider.isSupported && ObjectTrackingProvider.isSupported
        }
    }
    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }
    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredAuthorizationsAreGranted
    }
    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
    func didLeaveImmersiveSpace() {
        // Stop the provider; the provider that just ran in the
        // immersive space is now in a paused state and isn't needed
        // anymore. When a person reenters the immersive space,
        // run a new provider.
        logInfo("Stopping ARKit session to leave immersive space.")
        arkitSession.stop()
        immersiveSpaceState = .closed
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
        for await event in arkitSession.events {
            logInfo("\(event.description)")
            switch event {
            case .authorizationChanged(type: _, status: let status):
                logInfo("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = .providerNotAuthorized
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                logInfo("Data providers state changed: \(providers), \(state)")
                if let error {
                    logError("Data provider reached an error state: \(error)")
                    errorState = .sessionError(error)
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
    
    func runARKitSession() async {

        let referenceObjects = objectTracking.referenceObjectLoader.enabledReferenceObjects
        
        
//        var trackingProviders: [DataProvider] = [imageTracking]
        var trackingProviders: [DataProvider] = []

        // Only provision the objectTracking provider when needed
        if !referenceObjects.isEmpty {
            // TODO: a new session should be started when entering the immersive space, currently
            // this is done 1 time during initialisation of the AppModel, which makes it not
            // possible to load new selected reference objects during runtime
            objectTrackingProvider = ObjectTrackingProvider(referenceObjects: referenceObjects)
            if let objectTrackingProvider = objectTrackingProvider {                trackingProviders.append(objectTrackingProvider)
            }
            else {
                logError("TRACKING ERROR: Failed to create ObjectTrackingProvider.")
            }
        }
        do {
            logInfo("Run arkitSession...")
            try await arkitSession.run(trackingProviders)
            logInfo("ArkitSession running!")
        } catch {
            logInfo("Exception running arkitSession: \(error)")
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
                logInfo("[TRACKING] New image anchor added.")
                createImage(imageAnchor)
            case .updated:
                //logger.info("[TRACKING] image anchor updated.")
                updateImage(imageAnchor)
            case .removed:
                logInfo("[TRACKING] image anchor removed")
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
            logInfo("Image \(imageName) added")
            let quad = MeshResource.generatePlane(width: width, height: height)
            let entity = ModelEntity(mesh: quad, materials: [OcclusionMaterial()])

            entityMap[anchor.id] = entity
            contentRoot.addChild(entity)
            imageAnchors[anchor.id] = anchor
        }
        
        if anchor.isTracked {
            var transform = Transform(matrix: anchor.originFromAnchorTransform)
            let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Align entity to Poster
            transform.rotation = transform.rotation * rotationX
            entityMap[anchor.id]?.transform = transform
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
        selectedWorld = VideoInfo.World.visvijver
        videoModel = VideoModel()
        videos[VideoInfo.World.visvijver] = VideoInfo(rotationDegrees: -90.0)
        videos[VideoInfo.World.visvijver_qoocam_topaz] = VideoInfo(rotationDegrees: 180.0)

        
        if !isSimulator {
            runBackgroundTasks()
        }
        screen2tableDistance = isSingleUser ? 0.0 : 20.0
    }
    let isSimulator: Bool = {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }()
    
    func runBackgroundTasks() {
        logInfo("runBackgroundTasks...")
        
        if !areAllDataProvidersSupported {
            errorState = .providerNotSupported
            logInfo("Not all providers supported, no background tasks will be started!")
            return
        }
        logInfo("All providers supported")
        
        Task {
            if await !areAllDataProvidersAuthorized() {
                errorState = .providerNotAuthorized
            }
            
            else {
    
                // In order to start the ARKit session, the image- and objectTracking providers should
                // be configured. For the first, this is already done. For the objectTracking however
                // the objects should be loaded first. After that the ARKit session can run with the configures providers
                
                logInfo("loading reference objects...")
                await objectTracking.referenceObjectLoader.loadBuiltInReferenceObjects()
                logInfo("reference objects loaded")
                Task {
                    await monitorSessionUpdates()
                }
            }
        }
    }
    func setupContentEntity() -> Entity {
        return contentRoot
    }
}
//@MainActor
let logger = Logger(subsystem: "com.biteplanet.XRDining", category: "general")

func logInfo(_ message: String) {
    logger.info("\(message, privacy: .public)")
}
func logError(_ message: String) {
    logger.error("\(message, privacy: .public)")
}
