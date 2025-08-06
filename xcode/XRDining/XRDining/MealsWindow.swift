//
//  MealsWindow.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/08/2025.
//

import SwiftUI

struct MealsWindow : Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            CarouselView()
//            .frame(width: 800, height: 500)
        }
//        .windowResizability(.contentSize)
    }
}
