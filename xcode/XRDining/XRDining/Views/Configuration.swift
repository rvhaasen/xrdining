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
                    ForEach(VideoInfo.World.allCases) { world in
                        Text(world.description)
                    }
                }
            //Spacer()
            }.onChange(of: appModel.selectedWorld) { oldValue, newValue in
                print("Picker selection changed from \(oldValue) to \(newValue)")
                // Add any custom logic here
                do {
                    try appModel.videoModel?.loadVideo(named: newValue.description)
                } catch {
                    print("Could not load video file \"\(newValue.description).mp4\"")
                    return
                }
            }
            VStack(spacing: 20) {
                Toggle(isOn: $appModel.isSingleUser) {
                    Label("single-user", systemImage: "person")
                }
                Toggle(isOn: $appModel.doObjectDetection) {
                    Label("object detection", systemImage: "magnifyingglass")
                }
                HStack {
                    Text("Rotation angle:")
                    Text(String(format: "%.0f", appModel.sphereAngle))
                }
                Slider(value: $appModel.sphereAngle,
                       in: -180...180,
                       step: 1)
                HStack {
                    Text("Position offset")
                    Text(String(format: "%.0f", appModel.positionOffset))
                }
                Slider(value: $appModel.positionOffset,
                    in: -45...45,
                    step: 1)
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
        .frame(maxWidth: 700)
        .font(.title3)

    }
}

#Preview(windowStyle: .automatic) {
     let model = AppModel()
    //model.selectedWorld = "Test"
    Configuration()
        .environment(model)
}
