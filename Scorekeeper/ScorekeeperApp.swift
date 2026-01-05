import SwiftUI
import SwiftData

@main
struct ScorekeeperApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            GameSession.self,
            Player.self,
            Round.self,
            SpadesRound.self,
            HeartsRound.self,
            UnoRound.self,
            CaboRound.self
        ])
    }
}
