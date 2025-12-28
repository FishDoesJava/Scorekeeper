//
//  SpadesEngine.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import Foundation

struct SpadesEngine {

    struct Settings {
        var targetScore: Int = 500
        var nilBonus: Int = 100
        var blindNilBonus: Int = 200
        var bagsPenaltyEvery: Int = 10
        var bagsPenalty: Int = 100
    }

    struct TeamSnapshot {
        var score: Int
        var bags: Int
    }

    struct RoundResult {
        var teamA_deltaScore: Int
        var teamA_deltaBags: Int
        var teamB_deltaScore: Int
        var teamB_deltaBags: Int
    }

    /// Team assignment: players[0] & players[2] = Team A, players[1] & players[3] = Team B
    static func teams(session: GameSession) -> (teamA: [Player], teamB: [Player]) {
        let ps = session.players
        guard ps.count == 4 else { return ([], []) }
        return ([ps[0], ps[2]], [ps[1], ps[3]])
    }

    static func runningTeamSnapshots(session: GameSession, settings: Settings) -> (TeamSnapshot, TeamSnapshot) {
        var a = TeamSnapshot(score: 0, bags: 0)
        var b = TeamSnapshot(score: 0, bags: 0)

        for r in session.spadesRounds.sorted(by: { $0.index < $1.index }) {
            let delta = scoreRound(session: session, round: r, settings: settings, currentA: a, currentB: b)
            a.score += delta.teamA_deltaScore
            a.bags += delta.teamA_deltaBags
            b.score += delta.teamB_deltaScore
            b.bags += delta.teamB_deltaBags

            // Apply bag penalties after updating bags
            a = applyBagsPenalty(a, settings: settings)
            b = applyBagsPenalty(b, settings: settings)
        }

        return (a, b)
    }

    /// Computes per-round deltas; bag penalty is applied in running snapshots (not inside this delta).
    static func scoreRound(
        session: GameSession,
        round: SpadesRound,
        settings: Settings,
        currentA: TeamSnapshot,
        currentB: TeamSnapshot
    ) -> RoundResult {

        let (teamAPlayers, teamBPlayers) = teams(session: session)
        let teamAIds = Set(teamAPlayers.map(\.id))
        let teamBIds = Set(teamBPlayers.map(\.id))

        func nilDelta(for pid: UUID, tricks: Int, isNil: Bool, isBlindNil: Bool) -> Int {
            if isBlindNil {
                return (tricks == 0) ? settings.blindNilBonus : -settings.blindNilBonus
            }
            if isNil {
                return (tricks == 0) ? settings.nilBonus : -settings.nilBonus
            }
            return 0
        }

        // Team totals
        var bidA = 0, bidB = 0
        var tricksA = 0, tricksB = 0
        var nilBonusA = 0, nilBonusB = 0

        for pid in round.playerIds {
            let bid = max(0, min(round.bid(for: pid), 13))
            let t = max(0, min(round.tricks(for: pid), 13))
            let n = round.isNil(for: pid)
            let bn = round.isBlindNil(for: pid)

            // bids: nil/blind nil are still "0 bid" effectively, so adding bid is fine
            if teamAIds.contains(pid) { bidA += bid; tricksA += t; nilBonusA += nilDelta(for: pid, tricks: t, isNil: n, isBlindNil: bn) }
            if teamBIds.contains(pid) { bidB += bid; tricksB += t; nilBonusB += nilDelta(for: pid, tricks: t, isNil: n, isBlindNil: bn) }
        }

        // Contract scoring
        func contractDelta(bid: Int, tricks: Int) -> (score: Int, bags: Int) {
            if tricks >= bid {
                let bags = tricks - bid
                return (10 * bid, bags)
            } else {
                return (-10 * bid, 0)
            }
        }

        let cA = contractDelta(bid: bidA, tricks: tricksA)
        let cB = contractDelta(bid: bidB, tricks: tricksB)

        // Total deltas (nil bonuses affect score only)
        let aScore = cA.score + nilBonusA
        let bScore = cB.score + nilBonusB

        return RoundResult(
            teamA_deltaScore: aScore,
            teamA_deltaBags: cA.bags,
            teamB_deltaScore: bScore,
            teamB_deltaBags: cB.bags
        )
    }

    static func applyBagsPenalty(_ snapshot: TeamSnapshot, settings: Settings) -> TeamSnapshot {
        guard settings.bagsPenaltyEvery > 0 else { return snapshot }
        var s = snapshot
        while s.bags >= settings.bagsPenaltyEvery {
            s.score -= settings.bagsPenalty
            s.bags -= settings.bagsPenaltyEvery
        }
        return s
    }

    static func isGameOver(teamA: TeamSnapshot, teamB: TeamSnapshot, target: Int) -> Bool {
        return teamA.score >= target || teamB.score >= target
    }

    static func winners(teamA: TeamSnapshot, teamB: TeamSnapshot) -> [String] {
        if teamA.score == teamB.score { return ["Team A", "Team B"] }
        return (teamA.score > teamB.score) ? ["Team A"] : ["Team B"]
    }
}
