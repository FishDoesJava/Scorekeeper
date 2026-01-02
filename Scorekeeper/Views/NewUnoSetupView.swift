//
//  NewUnoSetupView.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/11/25.
//

import SwiftUI
import SwiftData

struct NewUnoSetupView: View {
    @Environment(\.modelContext) private var modelContext
    let onStarted: (GameSession) -> Void

    @State private var playerCount = 4
    @State private var names: [String] = Array(repeating: "", count: UnoRules.maxPlayers)
    @State private var targetText = "\(UnoRules.defaultTarget)"

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New: UNO")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    Stepper("Players: \(playerCount)", value: $playerCount, in: UnoRules.minPlayers...UnoRules.maxPlayers)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Score (first to reach wins)")
                            .foregroundStyle(AppTheme.secondary)

                        TextField("\(UnoRules.defaultTarget)", text: $targetText)
                            .keyboardType(.numberPad)
                            .modifier(DarkTextFieldStyle())
                    }

                    VStack(spacing: 10) {
                        ForEach(0..<playerCount, id: \.self) { i in
                            TextField("Player \(i+1)", text: $names[i])
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .modifier(DarkTextFieldStyle())
                        }
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

    private func startGame() {
        let players = (0..<playerCount).map { i in
            Player(name: names[i].isEmpty ? "Player \(i+1)" : names[i])
        }
        let session = GameSession(gameType: .uno, players: players)
        let target = Int(targetText) ?? UnoRules.defaultTarget
        session.unoTargetScore = max(10, min(target, 2000))

        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            print("NewUnoSetupView: save error:", error)
        }
        onStarted(session)
    }
}
