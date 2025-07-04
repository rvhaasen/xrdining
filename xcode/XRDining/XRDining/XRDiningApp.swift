//
//  XRDiningApp.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI


@main
struct XRDiningApp: App {

    @State var appModel = AppModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        Group {
            XRDiningWindow()
            ImmersiveSpace(id: appModel.immersiveSpaceID) {
                ImmersiveView()
                    .onAppear {
                        appModel.immersiveSpaceState = .open
                    }
                    .onDisappear {
                        appModel.immersiveSpaceState = .closed
                    }
            }
        }
        .environment(appModel)
//        .onChange(of: scenePhase) { _, newPhase in
//            switch newPhase {
//            case .background:
//                appModel.arkitSession.pause()
//            default:
//                break
//            }
//        }
    }
}
