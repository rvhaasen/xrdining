/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the SharePlay button.
*/

import CoreTransferable
import GroupActivities
import SwiftUI
import UIKit

struct SharePlayButton<ActivityType: GroupActivity & Transferable & Sendable>: View {
    @Environment(AppModel.self) var appModel
    
    @ObservedObject
    private var groupStateObserver = GroupStateObserver()
    
    @State
    private var isActivitySharingViewPresented = false
    
    @State
    private var isActivationErrorViewPresented = false
    
    private let activitySharingView: ActivitySharingView<ActivityType>
    
    let text: any StringProtocol
    let activity: ActivityType
    let openImmersive: () -> Void
    
    init(_ text: any StringProtocol, activity: ActivityType, openImmersive : @escaping () -> Void) {
        self.text = text
        self.activity = activity
        self.openImmersive = openImmersive
        
        self.activitySharingView = ActivitySharingView {
            activity
        }
    }
    
    var body: some View {
        ZStack {
            ShareLink(item: activity, preview: SharePreview(text)).hidden()
            
            // The logic is as follows:
            // initial, isActivitySharingViewPresented is false and this will
            // set it to True when evaluating the Button.
            // Because it is a state for this View, the Button will be redrawn.
            // It will set isActivitySharingViewPresented to True, but it already was
            // The Share sheet will be shown, which will enable choosing a recipient
            // for the connection. When the connection has been established the sheet
            // will disappear and isActivitySharingViewPresented will automatically be
            // set to False. This will again evaluate the button, which will now find
            // groupStateObserver.isEligibleForGroupSession set to True.
            // This will start the shared activity.
            // At this moment, the main window is shows slightly rotated because of
            // the default spatial template which is being applied. This places
            // the participants (2 in this case) next to eachother looking toward the
            // screen. From a participant view, the other participant is either to the
            // left or the right (order is not determined, this probably can be done
            // using custom template and role assignment).
                
            Button(text, systemImage: "shareplay") {
                if groupStateObserver.isEligibleForGroupSession {
                    // The application screen will appear on the
                    // left side of the 'caller' and on the right
                    // side of the 'called'. It is important to know
                    // the position in order to rotate the menu-screen
                    // correctly toward each user
                    appModel.spatialTemplateRole = DiningTemplate.Role.caller
                    Task.detached {
                        do {
                            _ = try await activity.activate()
                            //await openImmersive()
                        } catch {
                            print("Error activating activity: \(error)")
                            
                            Task { @MainActor in
                                isActivationErrorViewPresented = true
                            }
                        }
                    }
                } else {
                    isActivitySharingViewPresented = true
                }
            }
            .tint(.green)
            .sheet(isPresented: $isActivitySharingViewPresented) {
                activitySharingView
            }
            .alert("Unable to start game", isPresented: $isActivationErrorViewPresented) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Please try again later.")
            }
        }
    }
}

struct ActivitySharingView<ActivityType: GroupActivity & Sendable>: UIViewControllerRepresentable {
    let preparationHandler: () async throws -> ActivityType

    func makeUIViewController(context: Context) -> GroupActivitySharingController {
        GroupActivitySharingController(preparationHandler: preparationHandler)
    }

    func updateUIViewController(_: GroupActivitySharingController, context: Context) {}
}
