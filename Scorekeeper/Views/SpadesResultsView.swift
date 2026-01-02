//
//  SpadesResultsView.swift
//  Scorekeeper
//
//  Created by GitHub Copilot on 01/02/26.
//

import SwiftUI

struct SpadesResultsView: View {
    @Bindable var session: GameSession
    @State private var fireConfetti = false

    var body: some View {
        let settings = SpadesEngine.Settings(targetScore: session.spadesTargetScore)
        let snaps = SpadesEngine.runningTeamSnapshots(session: session, settings: settings)
        let winners = SpadesEngine.winners(teamA: snaps.0, teamB: snaps.1)

        ZStack {
            ThemedContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Spades — Results 🍾")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    Text("Winners")
                        .foregroundStyle(AppTheme.secondary)

                    VStack(spacing: 8) {
                        ForEach(winners, id: \.self) { w in
                            Text(w)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(AppTheme.accent.opacity(0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Divider().overlay(AppTheme.primary.opacity(0.15))

                    Text("Team Scores")
                        .foregroundStyle(AppTheme.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Team A")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text(session.players.indices.count >= 1 ? session.players[0].name + " & " + (session.players.count > 2 ? session.players[2].name : "") : "")
                                .font(.system(size: 12))
                        }
                        Spacer()
                        Text("\(snaps.0.score)  |  bags: \(snaps.0.bags)")
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Team B")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text(session.players.indices.count >= 2 ? session.players[1].name + " & " + (session.players.count > 3 ? session.players[3].name : "") : "")
                                .font(.system(size: 12))
                        }
                        Spacer()
                        Text("\(snaps.0.score)  |  bags: \(snaps.0.bags)")
                    }

                    Spacer()
                }
                .padding()
            }

            ConfettiView(isActive: $fireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .onAppear {
            Haptics.success()
            fireConfetti = true
        }
    }
}
