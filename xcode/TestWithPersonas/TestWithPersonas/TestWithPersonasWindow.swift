//
//  TestWithPersonasWindow.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 24/06/2025.
//

import SwiftUI

struct TestWithPersonasWindow : Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            MainView()
            .frame(width: 900, height: 600)
        }
        .windowResizability(.contentSize)
    }
}
