//
//  AppModel.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

import Foundation
import SwiftUI
import Observation

import RealityKit

/// Maintains app-wide state

@Observable @MainActor
class AppModel {
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
    var selectedWorld: World// = .none
    
    var isSingleUser: Bool = false
    var doObjectDetection: Bool = false
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var skyBox: Entity? = nil
    
    var videoModel: VideoModel?
    
    var sphereCenter = SIMD3<Float>(0, 30, -0.5)
    
    // Constructor
    init(selectedWorld: World = .visvijver) {
        
        videoModel = VideoModel()
        
        self.selectedWorld = selectedWorld
    }
//    func createSkyboxEntity() -> Entity {
//        let entity = Entity()
//        let material = UnlitMaterial(color: .blue)
//        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 30), materials: [material]))
//        entity.scale *= .init(x:-1, y:1, z:1)
//        
//        let rotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
//        entity.orientation = rotation * entity.orientation
//
//        return entity
//        
//    }
}
