//
//  SessionController.swift
//  XRDining
//
//  Created by Rick van Haasen on 24/06/2025.
//
import GroupActivities
import Observation

@Observable @MainActor
final class SessionController {
    let session: GroupSession<PersonasActivity>
    let messenger: GroupSessionMessenger
    let systemCoordinator: SystemCoordinator
    
    var players = [Participant: PlayerModel]()
//    {
//        didSet {
//            if oldValue != players {
//                updateCurrentPlayer()
//                updateLocalParticipantRole()
//            }
//        }
//    }
    var localPlayer: PlayerModel {
        get {
            players[session.localParticipant]!
        }
        set {
            if newValue != players[session.localParticipant] {
                players[session.localParticipant] = newValue
                //shareLocalPlayerState(newValue)
            }
        }
    }
    var screenDistance: Double
 

    init?(_ groupSession: GroupSession<PersonasActivity>, appModel: AppModel) async {
        guard let groupSystemCoordinator = await groupSession.systemCoordinator else {
            return nil
        }
        screenDistance = Double(appModel.screen2tableDistance)
        session = groupSession
        // Create the group session messenger for the session controller, which it uses to keep the game in sync for all participants.
        messenger = GroupSessionMessenger(session: session)

        systemCoordinator = groupSystemCoordinator
        updateSpatialTemplatePreference()
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()
        session.join()
    }
    func updateSpatialTemplatePreference() {
        systemCoordinator.configuration.spatialTemplatePreference = .custom(DiningTemplate(screenDistance: screenDistance))
    }
    func configureSystemCoordinator() {
        // Let the system coordinator show each players' spatial Persona in the immersive space.
        systemCoordinator.configuration.supportsGroupImmersiveSpace = true
    }
    func gameStateChanged() {
        updateSpatialTemplatePreference()
    }
}
