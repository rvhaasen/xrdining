//
//  XRDiningWindow.swift
//  XRDining
//
//  Created by Rick van Haasen on 24/06/2025.
//

import SwiftUI

struct XRDiningWindow : Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            MainView()
            .frame(width: 800, height: 500)
        }
        .windowResizability(.contentSize)
    }
}
