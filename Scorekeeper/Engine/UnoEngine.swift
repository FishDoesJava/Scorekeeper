//
//  UnoEngine.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/11/25.
//

import Foundation

struct UnoEngine {

    static func runningTotals(session: GameSession) -> [UUID: Int] {
        var totals: [UUID: Int] = [:]
        for p in session.orderedPlayers { totals[p.id] = 0 }

        for r in session.unoRounds {
            for pid in session.orderedPlayers.map(\.id) {
                totals[pid, default: 0] += r.score(for: pid)
            }
        }
        return totals
    }

    static func isGameOver(totals: [UUID: Int], target: Int) -> Bool {
        totals.values.contains(where: { $0 >= target })
    }

    static func winnersHighestTotal(totals: [UUID: Int]) -> [UUID] {
        let maxTotal = totals.values.max() ?? 0
        return totals.filter { $0.value == maxTotal }.map(\.key)
    }
}
