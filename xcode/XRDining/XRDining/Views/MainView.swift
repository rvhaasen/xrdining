//
//  MainView.swift
//  XRDining
//
//  Created by Rick van Haasen on 24/06/2025.
//

import GroupActivities
import SwiftUI
internal import Combine
import Playgrounds

struct MainView: View {
    @Environment(AppModel.self) var appModel
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    
    var body: some View {
        //ContentView()
        @Bindable var appModel = appModel
        
        NavigationStack {
            VStack {
                WelcomeBanner().offset(y: 40)
                NavigationLink {
                    Configuration()
                } label: {
                    Text("Configuration")
                }.padding(.bottom, 20)
                ToggleImmersiveSpaceButton()
            }
            .font(.title2)
            .padding(.bottom, 20)
            
            Divider()
            
            SharePlayButton("Share XRDining activity", activity: PersonasActivity())
                .padding(.vertical, 50)
                .font(.title2)
        }
        .task(observeGroupSessions)
        .onChange(of: scenePhase, initial: true) {
                print("HomeView scene phase: \(scenePhase)")
                if scenePhase == .active {
                    Task {
                        // When returning from the background, check if the authorization has changed.
                        await appModel.queryWorldSensingAuthorization()
                    }
                } else {
                    // Make sure to leave the immersive space if this view is no longer active
                    // - such as when a person closes this view - otherwise they may be stuck
                    // in the immersive space without the controls this view provides.
                    if appModel.immersiveSpaceState == .open {
                        Task {
                            await dismissImmersiveSpace()
                            appModel.didLeaveImmersiveSpace()
                        }
                    }
                }
            }

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
    struct WelcomeBanner: View {
        var body: some View {
            HStack(alignment: .center) {
                Image(systemName: "figure.fishing")
                    .foregroundStyle(.cyan.gradient)
                    .scaleEffect(x: -1)
                Image(systemName: "figure.climbing")
                    .foregroundStyle(.yellow.gradient)
                Image(systemName: "figure.badminton")
                    .foregroundStyle(.orange.gradient)
                    .scaleEffect(x: -1)
                
                Image(systemName: "figure.run.square.stack.fill")
                    .font(.system(size: 170))
                    .foregroundStyle(.purple.gradient)
                    .offset(y: -20)
                
                Image(systemName: "figure.archery")
                    .foregroundStyle(.red.gradient)
                Image(systemName: "figure.play")
                    .foregroundStyle(.green.gradient)
                    .scaleEffect(x: -1)
                Image(systemName: "figure.surfing")
                    .foregroundStyle(.blue.gradient)
            }
            .font(.system(size: 50))
            .frame(maxHeight: .infinity)
        }
    }
}
#Preview(windowStyle: .automatic) {
    MainView()
        .environment(AppModel())
}


#Playground {
    #Preview {
        Text("Hello, world!")
    }
}

