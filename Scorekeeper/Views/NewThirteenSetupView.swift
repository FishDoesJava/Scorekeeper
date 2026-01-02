//
//  NewThirteenSetupView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI
import SwiftData

struct NewThirteenSetupView: View {
    @Environment(\.modelContext) private var modelContext
    let onStarted: (GameSession) -> Void

    @State private var playerCount = 4
    @State private var names: [String] = Array(repeating: "", count: 8)

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New: Thirteen")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    Stepper("Players: \(playerCount)", value: $playerCount, in: ThirteenRules.minPlayers...ThirteenRules.maxPlayers)

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
                        let players = (0..<playerCount).map { i in
                            Player(name: names[i].isEmpty ? "Player \(i+1)" : names[i])
                        }
                        let session = GameSession(gameType: .thirteen, players: players)
                        modelContext.insert(session)
                        try? modelContext.save()
                        onStarted(session)
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
}
