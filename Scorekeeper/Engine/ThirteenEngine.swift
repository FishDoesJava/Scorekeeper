//
//  ThirteenEngine.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import Foundation

struct ThirteenEngine {

    static func runningTotals(session: GameSession) -> [UUID: Int] {
        var totals: [UUID: Int] = [:]
        for p in session.orderedPlayers { totals[p.id] = 0 }

        for r in session.rounds {
            for pid in session.orderedPlayers.map(\.id) {
                totals[pid, default: 0] += r.score(for: pid)
            }
        }
        return totals
    }

    static func pickDealerForNextRound(
        session: GameSession,
        roundScores: [UUID: Int]
    ) -> UUID? {

        guard !roundScores.isEmpty else { return nil }

        let maxRound = roundScores.values.max() ?? 0
        var candidates = roundScores.filter { $0.value == maxRound }.map(\.key)
        if candidates.count == 1 { return candidates[0] }

        let priorTotals = runningTotals(session: session)
        var totalsAfter: [UUID: Int] = priorTotals
        for (pid, s) in roundScores { totalsAfter[pid, default: 0] += s }

        let maxTotal = candidates.map { totalsAfter[$0] ?? 0 }.max() ?? 0
        candidates = candidates.filter { (totalsAfter[$0] ?? 0) == maxTotal }
        if candidates.count == 1 { return candidates[0] }

        return candidates.randomElement()
    }

    static func winnersLowestTotal(session: GameSession) -> [UUID] {
        let totals = runningTotals(session: session)
        let minTotal = totals.values.min() ?? 0
        return totals.filter { $0.value == minTotal }.map(\.key)
    }
}
