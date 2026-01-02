//
//  NewSpadesSetupView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import SwiftUI
import SwiftData

struct NewSpadesSetupView: View {
    @Environment(\.modelContext) private var modelContext
    let onStarted: (GameSession) -> Void

    @State private var teamA_p1 = ""
    @State private var teamA_p2 = ""
    @State private var teamB_p1 = ""
    @State private var teamB_p2 = ""
    @State private var targetScoreText = "500"

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New: Spades")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Score")
                            .foregroundStyle(AppTheme.secondary)

                        TextField("500", text: $targetScoreText)
                            .keyboardType(.numberPad)
                            .modifier(DarkTextFieldStyle())
                    }

                    HStack(alignment: .top, spacing: 12) {
                        teamCard(title: "Team A", p1: $teamA_p1, p2: $teamA_p2)
                        teamCard(title: "Team B", p1: $teamB_p1, p2: $teamB_p2)
                    }

                    Button {
                        Haptics.tap()
                        startGame()
                    } label: {
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .padding()
            }
        }
    }

    private func teamCard(title: String, p1: Binding<String>, p2: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primary)

            TextField("Player 1", text: p1)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .modifier(DarkTextFieldStyle())

            TextField("Player 2", text: p2)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .modifier(DarkTextFieldStyle())
        }
        .padding(12)
        .background(AppTheme.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func startGame() {
        let a1 = teamA_p1.isEmpty ? "A1" : teamA_p1
        let a2 = teamA_p2.isEmpty ? "A2" : teamA_p2
        let b1 = teamB_p1.isEmpty ? "B1" : teamB_p1
        let b2 = teamB_p2.isEmpty ? "B2" : teamB_p2

        let players = [
            Player(name: a1),
            Player(name: b1),
            Player(name: a2),
            Player(name: b2)
        ]

        let session = GameSession(gameType: .spades, players: players)
        let target = Int(targetScoreText) ?? 500
        session.spadesTargetScore = max(50, min(target, 5000))

        modelContext.insert(session)
        do {
            try modelContext.save()
            print("NewSpadesSetupView: saved session id=\(session.id)")
            // show how many sessions are visible in this context
            let all = try modelContext.fetch(FetchDescriptor<GameSession>())
            print("NewSpadesSetupView: context session count=\(all.count)")
        } catch {
            print("NewSpadesSetupView: save error:", error)
        }

        onStarted(session)
    }
}
