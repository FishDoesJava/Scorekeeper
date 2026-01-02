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
                    }
                    .padding()
                }
            }
        }
        .task(id: id) {
            guard session?.id != id else { return }
            let descriptor = FetchDescriptor<GameSession>(
                predicate: #Predicate { $0.id == id }
            )
            session = try? modelContext.fetch(descriptor).first
        }
    }
}
