//
//  MainView.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 24/06/2025.
//

import GroupActivities
import SwiftUI
internal import Combine
//internal import Combine
//internal import Combine

struct MainView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        Group {
            //if appModel.immersiveSpaceState == .closed {
                ContentView()
            //}
        }
        .task(observeGroupSessions)
    }
    @Sendable
    func observeGroupSessions() async {
        for await session in PersonasActivity.sessions() {
            let sessionController = await SessionController(session, appModel: appModel)
            guard let sessionController else {
                continue
            }
            appModel.sessionController = sessionController

            // Create a task to observe the group session state and clear the
            // session controller when the group session invalidates.
            Task {
                for await state in session.$state.values {
                    guard appModel.sessionController?.session.id == session.id else {
                        return
                    }

                    if case .invalidated = state {
                        appModel.sessionController = nil
                        return
                    }
                }
            }
        }
    }

}
