//
//  XRDiningApp.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI
import GroupActivities


@main
struct XRDiningApp: App {

    @State var appModel = AppModel()
    @State private var log = LogStore()
    
    var body: some Scene {

        Group {
            XRDiningWindow()
        
            ImmersiveSpace(id: appModel.immersiveSpaceID) {
                ZStack {
                    ImmersiveView()
                }
                .groupActivityAssociation(.primary(appModel.immersiveSpaceID))
//                .groupActivityAssociation(.)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
            }
        }
        .environment(appModel)
        .environment(log)
    }
}
