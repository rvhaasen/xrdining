//
//  XRDiningWindow.swift
//  XRDining
//
//  Created by Rick van Haasen on 24/06/2025.
//

import SwiftUI
import GroupActivities

struct XRDiningWindow : Scene {
    @Environment(AppModel.self) var appModel
    @Environment(LogStore.self) var log
    
    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            MainView()
//            .groupActivityAssociation(.primary("MainWindow"))
            .groupActivityAssociation(.none)
            //.frame(width: 800, height: 800)
            .frame(minWidth: 300, idealWidth: 800, maxWidth: 1200, minHeight: 300, idealHeight: 800, maxHeight: 900)
            //        .opacity(appModel.gardenOpen ? 0 : 1)
            .opacity(appModel.immersiveSpaceState == .open ? 0 : 1)
            
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        .defaultSize(CGSize(width: 800, height: 800))
        .persistentSystemOverlays(appModel.immersiveSpaceState == .open ? .hidden : .visible)
        WindowGroup(id: "console") {
            LogConsoleView().environment(log)
        }
    }
}
