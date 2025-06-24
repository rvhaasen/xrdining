//
//  TestWithPersonasApp.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI

@main
struct TestWithPersonasApp: App {

    @State var appModel = AppModel()

    var body: some Scene {
        Group {
            TestWithPersonasWindow()
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
     }
}
