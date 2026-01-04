//
//  CaboResultsView.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/19/25.
//

import SwiftUI

struct CaboResultsView: View {
    @Bindable var session: GameSession
    @State private var fireConfetti = false

    private var totals: [UUID: Int] {
        CaboEngine.runningTotals(session: session)
    }

    private var winners: [UUID] {
        CaboEngine.winnersLowestTotal(totals: totals)
    }

    var body: some View {
        ZStack {
            ThemedContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Cabo — Results 🍾")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    Text("Winner")
                        .foregroundStyle(AppTheme.secondary)

                    VStack(spacing: 8) {
                        ForEach(session.orderedPlayers.filter { winners.contains($0.id) }, id: \.id) { p in
                            Text("\(p.name) — \(totals[p.id, default: 0])")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(AppTheme.accent.opacity(0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Divider().overlay(AppTheme.primary.opacity(0.15))

                    Text("All Players")
                        .foregroundStyle(AppTheme.secondary)

                    ForEach(session.orderedPlayers, id: \.id) { p in
                        HStack {
                            Text(p.name)
                            Spacer()
                            Text("\(totals[p.id, default: 0])")
                                .foregroundStyle(AppTheme.secondary)
                        }
                        .padding(.vertical, 6)
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
