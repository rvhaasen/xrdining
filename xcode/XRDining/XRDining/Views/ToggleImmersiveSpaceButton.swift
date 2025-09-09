//
//  ToggleImmersiveSpaceButton.swift
//  XRDining
//
//  Created by Rick van Haasen on 18/06/2025.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel
    
    let openImmersive: () -> Void
    
    init( openImmersive: @escaping () -> Void) {
        self.openImmersive = openImmersive
    }
    var body: some View {
        Button {
            openImmersive()
        } label: {
            Text(appModel.immersiveSpaceState == .open ? "Hide Immersive Space" : "Show Immersive Space").font(.title)
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
