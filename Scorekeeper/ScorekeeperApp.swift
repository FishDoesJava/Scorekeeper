//
//  ScorekeeperApp.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

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
            HeartsRound.self
        ])
    }
}
