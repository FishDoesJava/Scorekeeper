//
//  SessionRouteView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import SwiftUI
import SwiftData

struct SessionRouteView: View {
    @Environment(\.modelContext) private var modelContext
    let id: UUID
    @State private var session: GameSession?
    @State private var debugMessage: String?
    @State private var fetchedCount: Int?

    init(id: UUID, initialSession: GameSession? = nil) {
        self.id = id
        _session = State(initialValue: initialSession)
    }

    var body: some View {
        Group {
            if let s = session {
                switch s.gameType {
                case .thirteen:
                    ThirteenScoringView(session: s)
                case .spades:
                    SpadesScoringView(session: s)
                }
            } else {
                ThemedContainer {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading game…")
                            .foregroundStyle(AppTheme.secondary)
                        
                        if let msg = debugMessage {
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 6)
                        }
                        
                        if let count = fetchedCount {
                            Text("Known sessions: \(count)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.secondary)
                        }
                        
                        Button("Force reload") {
                            debugMessage = nil
                            fetchedCount = nil
                            Task {
                                await performFetch()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        }
        .task(id: id) {
            if session == nil {
                await performFetch()
            }
        }
    }

    private func performFetch() async {
        let allDesc = FetchDescriptor<GameSession>()
        do {
            let all = try modelContext.fetch(allDesc)
            fetchedCount = all.count
        } catch {
            fetchedCount = nil
            debugMessage = "fetch all error: \(error.localizedDescription)"
            print("SessionRouteView fetch all error:", error)
        }

        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            if let fetched = try modelContext.fetch(descriptor).first {
                session = fetched
            } else {
                debugMessage = "no session found for id"
                print("SessionRouteView: no session found for id \(id)")
            }
        } catch {
            debugMessage = "fetch error: \(error.localizedDescription)"
            print("SessionRouteView fetch error:", error)
        }
    }
}
