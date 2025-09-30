//
//  LogConsoleView.swift
//  XRDining
//
//  Created by Rick van Haasen on 28/09/2025.
//

import SwiftUI

struct LogConsoleView: View {
    @Environment(LogStore.self) private var log
    @Environment(\.openWindow) private var openWindow
    
    @State private var followTail = true
    @State private var filter: LogStore.Level? = nil
    @State private var query = ""

    var body: some View {
        VStack(spacing: 8) {
            // Toolbar
            HStack {
                Menu {
                    Button("All") { filter = nil }
                    Divider()
                    ForEach(LogStore.Level.allCases, id: \.self) { lvl in
                        Button(lvl.rawValue.uppercased()) { filter = lvl }
                    }
                } label: {
                    filterLabel                 // this is your View label
                  }
                TextField("Filter text…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Toggle("Follow", isOn: $followTail).toggleStyle(.switch)
                Spacer()
                Button("Copy last 200") { copyLast() }
                Button("Clear") { log.entries.removeAll() }
            }
            .padding(.horizontal)

            Divider()

            // Log list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredEntries) { e in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(ts(e.date)).foregroundStyle(.secondary).monospacedDigit()
                                Text(tag(e.level)).font(.caption).monospaced().foregroundStyle(color(e.level))
                                Text(e.message).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                            }
                            .id(e.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .onChange(of: log.entries.count) {
                    guard followTail, let last = log.entries.last else { return }
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 320)
        .onDisappear {
            openWindow(id: "MainWindow")
        }
    }

    private var filteredEntries: [LogStore.Entry] {
        log.entries.filter { e in
            (filter == nil || e.level == filter!) &&
            (query.isEmpty || e.message.localizedCaseInsensitiveContains(query))
        }
    }
    private func ts(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f.string(from: d)
    }
    private func tag(_ l: LogStore.Level) -> String { switch l {
        case .debug: return "DBG"; case .info: return "INF"; case .warn: return "WRN"; case .error: return "ERR" } }
    private func color(_ l: LogStore.Level) -> Color { switch l {
        case .debug: return .gray; case .info: return .cyan; case .warn: return .yellow; case .error: return .red } }
    private func copyLast(_ n: Int = 200) {
        let slice = filteredEntries.suffix(n).map { "[\(ts($0.date))] \($0.level.rawValue.uppercased()) \($0.message)" }.joined(separator: "\n")
        UIPasteboard.general.string = slice
    }
    private var filterLabel: some View {
        HStack { Text("Level:"); Text(filter?.rawValue.uppercased() ?? "ALL").bold() }
    }
}
