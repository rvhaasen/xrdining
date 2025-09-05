//
//  ResourceHelpers.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/09/2025.
//

import Foundation
func listResourceNames(
    in bundle: Bundle = .main,
    subdirectory: String? = nil,
    allowedExtensions: Set<String>? = nil
) -> [String] {
    guard let root = (subdirectory != nil)
        ? bundle.resourceURL?.appendingPathComponent(subdirectory!)
        : bundle.resourceURL
    else { return [] }

    let keys: [URLResourceKey] = [.isRegularFileKey, .nameKey, .isDirectoryKey]
    let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys)!
    var results: [String] = []

    for case let url as URL in e {
        let values = try? url.resourceValues(forKeys: Set(keys))
        guard values?.isDirectory == false else { continue }
        if let allowed = allowedExtensions {
            let ext = url.pathExtension.lowercased()
            if ext.isEmpty || !allowed.contains(ext) { continue }
        }
        results.append(url.lastPathComponent)
    }
    return results.sorted()
}

// Examples
let allFiles = listResourceNames()
let videos   = listResourceNames(subdirectory: "Media/Videos", allowedExtensions: ["mp4","mov"])
let audio    = listResourceNames(subdirectory: "Media/Audio",  allowedExtensions: ["m4a","mp3","wav"])

