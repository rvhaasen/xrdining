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
    
    var game: GameModel {
        get {
            gameSyncStore.game
        }
        set {
            if newValue != gameSyncStore.game {
                gameSyncStore.game = newValue
                shareLocalGameState(newValue)
            }
        }
    }
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
    
    var gameSyncStore = GameSyncStore() {
        didSet {
            gameStateChanged()
        }
    }
    
    var screenDistance: Double
    var spatialTemplateRole: DiningTemplate.Role

    init?(_ groupSession: GroupSession<PersonasActivity>, appModel: AppModel) async {
        guard let groupSystemCoordinator = await groupSession.systemCoordinator else {
            return nil
        }
        appModel.currentGroupSession = groupSession
        
        spatialTemplateRole = appModel.spatialTemplateRole
        screenDistance = Double(appModel.screen2tableDistance)
        session = groupSession
        // Create the group session messenger for the session controller, which it uses to keep the game in sync for all participants.
        messenger = GroupSessionMessenger(session: session)

        systemCoordinator = groupSystemCoordinator
        // RH It seems that next call does not apply the Spatial template yet,
        // After session.join() the default template is applied (persons in circular area around the screen)
        // Only after showing the immersive view, the template is applied...
        //updateSpatialTemplatePreference()
        //gameStateChanged()
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()

        gameStateChanged()

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
        updateLocalParticipantRole()
    }
    func updateLocalParticipantRole() {
        // Set and unset the participant's spatial template role based on updating game state.
        switch game.stage {
            case .waiting:
                //systemCoordinator.resignRole()
                systemCoordinator.assignRole(spatialTemplateRole)
            case .active:
                systemCoordinator.assignRole(spatialTemplateRole)
        }
    }
 
}
