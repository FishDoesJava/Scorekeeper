import SwiftUI
import SwiftData

struct NewHeartsSetupView: View {
    @Environment(\.modelContext) private var modelContext
    let onStarted: (GameSession) -> Void

    @State private var playerCount = 4
    @State private var names: [String] = Array(repeating: "", count: HeartsRules.maxPlayers)
    @State private var targetText = "\(HeartsRules.defaultTarget)"

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New: Hearts")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    Stepper("Players: \(playerCount)", value: $playerCount, in: HeartsRules.minPlayers...HeartsRules.maxPlayers)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Score (game ends when reached)")
                            .foregroundStyle(AppTheme.secondary)

                        TextField("\(HeartsRules.defaultTarget)", text: $targetText)
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
        let session = GameSession(gameType: .hearts, players: players)
        let target = Int(targetText) ?? HeartsRules.defaultTarget
        session.heartsTargetScore = max(10, min(target, 500))

        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            print("NewHeartsSetupView: save error:", error)
        }
        onStarted(session)
    }
}
