//
//  LogStore.swift
//  XRDining
//
//  Created by Rick van Haasen on 28/09/2025.
//

import SwiftUI
import Observation
internal import os

@MainActor @Observable
final class LogStore {
    enum Level: String, CaseIterable { case debug, info, warn, error }

    struct Entry: Identifiable {
        let id = UUID()
        let date = Date()
        let level: Level
        let message: String
        let file: String
        let function: String
        let line: Int
    }

    var entries: [Entry] = []
    var maxEntries = 2000

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "Console")

    func add(_ level: Level, _ message: String,
             file: String = #fileID, function: String = #function, line: Int = #line) {
        // Forward to unified logging (visible in Console.app)
        switch level {
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info:  logger.info("\(message, privacy: .public)")
        case .warn:  logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
        // Keep a rolling in-app buffer for the UI
        entries.append(.init(level: level, message: message, file: file, function: function, line: line))
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }
    }

    // Convenience
    func debug(_ m: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) { add(.debug, m(), file: file, function: function, line: line) }
    func info (_ m: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) { add(.info , m(), file: file, function: function, line: line) }
    func warn (_ m: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) { add(.warn , m(), file: file, function: function, line: line) }
    func error(_ m: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) { add(.error, m(), file: file, function: function, line: line) }
}
