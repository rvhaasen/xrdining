//
//  ObjectTrackingModel.swift
//  XRDining
//
//  Created by Rick van Haasen on 01/07/2025.
//

import Foundation
import ARKit

@MainActor
@Observable
// REFACTOR: put ReferenceObjectLoader directly in AppModel
class ObjectTrackingModel {
    
    let referenceObjectLoader = ReferenceObjectLoader()
    
//    var allRequiredProvidersAreSupported: Bool {
//        ObjectTrackingProvider.isSupported
//    }
}
