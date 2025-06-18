//
//  TestWithPersonasApp.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI

@main
struct TestWithPersonasApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
//        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
