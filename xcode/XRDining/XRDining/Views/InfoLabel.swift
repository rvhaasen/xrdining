/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A text view describing the current app state.
*/

import SwiftUI

struct InfoLabel: View {
    let appState: AppModel
    
    var body: some View {
        if let infoMessage {
            Text(infoMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
    }

    @MainActor
    var infoMessage: String? {
        if !appState.areAllDataProvidersSupported {
            return "Sorry, this app requires functionality that isn't supported on this platform."
        } else if !appState.allRequiredAuthorizationsAreGranted {
            return "Sorry, this app is missing necessary authorizations. You can change this in the Privacy & Security settings."
        }
        return nil
    }
}
