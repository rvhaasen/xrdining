/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom spatial template used to arrange spatial Personas
  during Guess Together's game stage.
*/

import GroupActivities
import Spatial

/// The team selection template contains three sets of seats:
///
/// 1. An seat to the left of the app window for the active player.
/// 2. Two seats to the right of the app window for the active player's
///    teammates.
/// 3. Five seats in front of the app window for the inactive team-members
///    and any audience members.
///
/// ```
///                  ┌────────────────────┐
///                  │   Guess Together   │
///                  │     app window     │
///                  └────────────────────┘
///
///
/// Active Player  %                       $  Active Team
///                                        $
///
///                      *  *  *  *  *
///
///                         Audience
///
/// ```
struct DiningTemplate: SpatialTemplate {
//    enum Role: String, SpatialTemplateRole {
//        case player
//        case activeTeam
//    }
    
//    static let player1Position = Point3D(x: 0, z: -1)
//    static let player2Position = Point3D(y: 0, z: -3)

    /// An array that represents the order the game adds participants to spatial template positions.
    var elements: [any SpatialTemplateElement] {

        let player1Element = SpatialTemplateElementPosition.app.offsetBy(x: -1, z: 20)
        let player2Element = SpatialTemplateElementPosition.app.offsetBy(x: 1, z: 20)
        //let player3Element = SpatialTemplateElementPosition.app.offsetBy(x: 0, z: -1)

        let activeTeamSeats: [any SpatialTemplateElement] = [
            .seat(
                position: player1Element,
                direction: .lookingAt(player2Element)
//                role: Role.activeTeam
            ),
            .seat(
                position: player2Element,
                direction: .lookingAt(player1Element),
//                role: Role.activeTeam
            ),
//            .seat(
//                position: player3Element,
//                direction: .lookingAt(player2Element),
////                role: Role.activeTeam
//            )

        ]
        
        return activeTeamSeats
    }
}
