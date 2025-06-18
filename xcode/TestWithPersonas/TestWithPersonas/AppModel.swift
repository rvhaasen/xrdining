//
//  AppModel.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI
import RealityKit

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var skyBox: Entity? = nil
    
    init() {
        skyBox = createSkyboxEntity()
    }
    func createSkyboxEntity() -> Entity {
        let entity = Entity()
        let material = UnlitMaterial(color: .blue)
        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
        entity.scale *= .init(x:-1, y:1, z:1)
        
        return entity
        
    }
}
