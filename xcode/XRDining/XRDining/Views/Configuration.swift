//
//  ObjectDetectionView.swift
//  XRDining
//
//  Created by Rick van Haasen on 27/06/2025.
//

import SwiftUI
import Playgrounds

struct Configuration: View {
    @Environment(AppModel.self) var appModel
    var body: some View {
        @Bindable var appModel = appModel

        // A Picker for selecting a world
        VStack {
            VStack {
                Text("Configuration")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 16)
                    .foregroundStyle(.green)
            }
            HStack{
                Text("360 degree environment:").font(.headline)
                Picker("Worlds", selection: $appModel.selectedWorld) {
                    ForEach(AppModel.World.allCases) { world in
                        Text(world.description)
                    }
                }
            }
            VStack {
                Toggle(isOn: $appModel.isSingleUser) {
                    Label("single-user", systemImage: "person")
                }
                Toggle(isOn: $appModel.doObjectDetection) {
                    Label("object detection", systemImage: "magnifyingglass")
                }
            }.frame(maxWidth: 250)
        }
        .padding()
        .frame(maxWidth: 700)
    }
}

#Preview(windowStyle: .automatic) {
    var model = AppModel()
    //model.selectedWorld = "Test"
    Configuration()
        .environment(model)
}
