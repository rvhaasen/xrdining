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
        VStack(spacing: 32) {
            Text("Configuration")
                .bold()
                .padding(.bottom, 16)
                .foregroundStyle(.green)
                .font(.title)
            HStack {
                Text("360 degree environment:")
                Picker("Worlds", selection: $appModel.selectedWorld) {
                    ForEach(AppModel.World.allCases) { world in
                        Text(world.description)
                    }
                }
            //Spacer()
            }
            VStack(spacing: 20) {
                Toggle(isOn: $appModel.isSingleUser) {
                    Label("single-user", systemImage: "person")
                }
                Toggle(isOn: $appModel.doObjectDetection) {
                    Label("object detection", systemImage: "magnifyingglass")
                }
            }
            NavigationLink {
                ObjectTrackingView()
            } label: {
                Text("Configure object tracking")
            }
            .disabled(!appModel.doObjectDetection)
            //.frame(maxWidth: 300)
        }
        .padding()
        .frame(maxWidth: 500)
        .font(.title3)
    }
}

#Preview(windowStyle: .automatic) {
     let model = AppModel()
    //model.selectedWorld = "Test"
    Configuration()
        .environment(model)
}
