//
//  GameModel.swift
//  XRDining
//
//  Created by Rick van Haasen on 03/09/2025.
//

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents the current state of the game
  in the SharePlay group session.
*/

import Foundation
import GroupActivities

struct GameModel: Codable, Hashable, Sendable {
    /// The game's current state, which includes pre-game and in-game stages.
    var stage: ActivityStage = .waiting
    
}

extension GameModel {
    
    enum ActivityStage: Codable, Hashable, Sendable {
        case waiting
        case active
    }
}
