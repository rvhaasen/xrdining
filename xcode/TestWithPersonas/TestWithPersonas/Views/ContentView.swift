//
//  ContentView.swift
//  TestWithPersonas
//
//  Created by Rick van Haasen on 18/06/2025.
//

//import GroupActivities
import SwiftUI
import RealityKit
import RealityKitContent
import Playgrounds

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    var body: some View {
        @Bindable var appModel = appModel
        NavigationStack {
            VStack {
                WelcomeBanner().offset(y: 20)
                NavigationLink {
                    Configuration()
                } label: {
                    Text("Configuration")
                }
                ToggleImmersiveSpaceButton()
            }
            .padding(.bottom, 20)
            
            Divider()
                
            SharePlayButton("Share XRDining activity", activity: PersonasActivity())
            .padding(.vertical, 50)
        }
    }
}
struct WelcomeBanner: View {
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "figure.fishing")
                .foregroundStyle(.cyan.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "figure.climbing")
                .foregroundStyle(.yellow.gradient)
            Image(systemName: "figure.badminton")
                .foregroundStyle(.orange.gradient)
                .scaleEffect(x: -1)
            
            Image(systemName: "figure.run.square.stack.fill")
                .font(.system(size: 170))
                .foregroundStyle(.purple.gradient)
                .offset(y: -20)
            
            Image(systemName: "figure.archery")
                .foregroundStyle(.red.gradient)
            Image(systemName: "figure.play")
                .foregroundStyle(.green.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "figure.surfing")
                .foregroundStyle(.blue.gradient)
        }
        .font(.system(size: 50))
        .frame(maxHeight: .infinity)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}


#Playground {
    #Preview {
        Text("Hello, world!")
    }
}
