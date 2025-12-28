//
//  FinalResultsView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

struct FinalResultsView: View {
    @Bindable var session: GameSession

    var body: some View {
        let totals = ThirteenEngine.runningTotals(session: session)
        let winners = ThirteenEngine.winnersLowestTotal(session: session)

        ThemedContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text("Thirteen — Results")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                Text("Winner")
                    .foregroundStyle(AppTheme.fg.opacity(0.8))

                VStack(spacing: 8) {
                    ForEach(session.players.filter { winners.contains($0.id) }, id: \.id) { p in
                        Text("\(p.name) — \(totals[p.id, default: 0])")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(AppTheme.accent.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Divider().overlay(AppTheme.fg.opacity(0.15))

                Text("All Players")
                    .foregroundStyle(AppTheme.fg.opacity(0.8))

                ForEach(session.players, id: \.id) { p in
                    HStack {
                        Text(p.name)
                        Spacer()
                        Text("\(totals[p.id, default: 0])")
                            .foregroundStyle(AppTheme.fg.opacity(0.8))
                    }
                    .padding(.vertical, 6)
                }

                Spacer()
            }
            .padding()
        }
    }
}
