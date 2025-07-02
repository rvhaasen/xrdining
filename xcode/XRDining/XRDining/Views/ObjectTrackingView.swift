/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface.
*/

import SwiftUI
import ARKit
import RealityKit
import UniformTypeIdentifiers

struct ObjectTrackingView: View {
    @Environment(AppModel.self) var appModel
    
    let referenceObjectUTType = UTType("com.apple.arkit.referenceobject")!

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var fileImporterIsOpen = false
    @State private var cakeFileImporterIsOpen = false
    
    
    @State var selectedReferenceObjectID: ReferenceObject.ID?

    //@State var cakeFiles: [URL] = []
    var body: some View {
        Group {
            if appModel.areAllDataProvidersSupported {
                referenceObjectList
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                InfoLabel(appState: appModel)
                    .padding(.horizontal, 30)
                    .frame(minWidth: 400, minHeight: 300)
                    .fixedSize()
            }
        }
        .glassBackgroundEffect()
        //        .toolbar {
        //            ToolbarItem(placement: .bottomOrnament) {
        //                   if appModel.canEnterImmersiveSpace {
        //                    VStack {
        //                        if appModel.immersiveSpaceState == .closed {
        //                            Button("Start Tracking \(appState.referenceObjectLoader.enabledReferenceObjectsCount) Object(s)") {
        //                                Task {
        //                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
        //                                    case .opened:
        //                                        break
        //                                    case .error:
        //                                        print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
        //                                    case .userCancelled:
        //                                        print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
        //                                    @unknown default:
        //                                        break
        //                                    }
        //                                }
        //                            }
        //                            .disabled(!appState.canEnterImmersiveSpace || appState.referenceObjectLoader.enabledReferenceObjectsCount == 0)
        //                        } else {
        //                            Button("Stop Tracking") {
        //                                Task {
        //                                    await dismissImmersiveSpace()
        //                                    appState.didLeaveImmersiveSpace()
        //                                }
        //                            }
        //
        //                            if !appState.objectTrackingStartedRunning {
        //                                HStack {
        //                                    ProgressView()
        //                                    Text("Please wait until all reference objects have been loaded")
        //                                }
        //                            }
        //                        }
        //
        //                        Text(appState.isImmersiveSpaceOpened ?
        //                             "This leaves the immersive space." :
        //                             "This enters an immersive space, hiding all other apps."
        //                        )
        //                        .foregroundStyle(.secondary)
        //                        .font(.footnote)
        //                        .padding(.horizontal)
        //                    }
        //                }
        //            }
        //        }
        .fileImporter(isPresented: $fileImporterIsOpen, allowedContentTypes: [referenceObjectUTType], allowsMultipleSelection: true) { results in
            switch results {
            case .success(let fileURLs):
                Task {
                    // Try to load each selected file as a reference object.
                    for fileURL in fileURLs {
                        guard fileURL.startAccessingSecurityScopedResource() else {
                            print("Failed to get sandboxed access to the file \(fileURL)")
                            return
                        }
                        await appModel.objectTracking.referenceObjectLoader.addReferenceObject(fileURL)
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                print("Failed to open file with error: \(error)")
            }
        }
    }
    @MainActor
    var referenceObjectList: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                List(selection: $selectedReferenceObjectID) {
                    ForEach(appModel.objectTracking.referenceObjectLoader.referenceObjects, id: \.id) { referenceObject in
                        ListEntryView(referenceObject: referenceObject, referenceObjectLoader: appModel.objectTracking.referenceObjectLoader)
                    }
                    .onDelete { indexSet in
                        appModel.objectTracking.referenceObjectLoader.removeObjects(atOffsets: indexSet)
                    }
                }
                .navigationTitle("Reference objects")

                HStack {
                    Text("Reference objects:")
//                        .padding(.trailing)
                    Spacer()
                    Button {
                        fileImporterIsOpen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add reference objects")
                }.padding()
                
                HStack {
                    Text("Objects to add on plate:")
                    Spacer()
                    Button {
                        cakeFileImporterIsOpen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add objects to be added on plate")
                }.padding()
            }
            .padding(.vertical)
            .disabled(appModel.immersiveSpaceState == .open)
            
        } detail: {
            if !appModel.objectTracking.referenceObjectLoader.didFinishLoading {
                VStack {
                    Text("Loading reference objects…")
                    ProgressView(value: appModel.objectTracking.referenceObjectLoader.progress)
                        .frame(maxWidth: 200)
                }
            } else if appModel.objectTracking.referenceObjectLoader.referenceObjects.isEmpty {
                Text("Tap the + button to add reference objects, or include some in the 'Reference Objects' group of the app's Xcode project.")
            } else {
                if let selectedObject = appModel.objectTracking.referenceObjectLoader.referenceObjects.first(where: { $0.id == selectedReferenceObjectID }) {
                    // Display the USDZ file that the reference object was displayed on in this detail view.
                    if let path = selectedObject.usdzFile, !fileImporterIsOpen {
                        Model3D(url: path) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(0.5)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Text("No preview available")
                    }
                } else {
                    Text("No object selected")
                }
            }
        }
    }
}
