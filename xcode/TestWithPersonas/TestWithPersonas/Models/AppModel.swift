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
final class AppModel {
    var sessionController: SessionController?

    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    var worlds: [String] = [
        "philips-visvijver",
        "lelienaan4",
        ""
    ]
    var selectedWorld: String = ""
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var skyBox: Entity? = nil
    
    init() {
        skyBox = createSkyboxEntity()
    }
    func createSkyboxEntity() -> Entity {
        let entity = Entity()
        let material = UnlitMaterial(color: .blue)
        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 30), materials: [material]))
        entity.scale *= .init(x:-1, y:1, z:1)
        
        let rotation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
        entity.orientation = rotation * entity.orientation

        entity.position.x = 0
        entity.position.z = 30
        entity.position.y = -0.5

        return entity
        
    }
}
