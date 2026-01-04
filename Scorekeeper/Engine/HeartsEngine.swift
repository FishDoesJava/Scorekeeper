//
//  HeartsEngine.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/08/25.
//

import Foundation

struct HeartsEngine {

    static func runningTotals(session: GameSession) -> [UUID: Int] {
        var totals: [UUID: Int] = [:]
        for p in session.orderedPlayers { totals[p.id] = 0 }

        for r in session.heartsRounds {
            for pid in session.orderedPlayers.map(\.id) {
                totals[pid, default: 0] += r.score(for: pid)
            }
        }
        return totals
    }

    static func isGameOver(totals: [UUID: Int], target: Int) -> Bool {
        totals.values.contains(where: { $0 >= target })
    }

    static func winnersLowestTotal(totals: [UUID: Int]) -> [UUID] {
        let minTotal = totals.values.min() ?? 0
        return totals.filter { $0.value == minTotal }.map(\.key)
    }
}
