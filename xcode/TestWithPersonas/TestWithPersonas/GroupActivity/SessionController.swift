//
//  SessionController.swift
//  TestWithPersonas
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
    
    init?(_ groupSession: GroupSession<PersonasActivity>, appModel: AppModel) async {
        guard let groupSystemCoordinator = await groupSession.systemCoordinator else {
            return nil
        }
        session = groupSession
        // Create the group session messenger for the session controller, which it uses to keep the game in sync for all participants.
        messenger = GroupSessionMessenger(session: session)

        systemCoordinator = groupSystemCoordinator

        session.join()
    }
}
