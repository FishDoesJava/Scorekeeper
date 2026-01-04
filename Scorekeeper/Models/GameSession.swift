//
//  GameSession.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var gameTypeRaw: String
    var isCompleted: Bool

    @Relationship(deleteRule: .cascade) var players: [Player]
    // Persist the intended player order (SwiftData may not preserve relationship ordering).
    var playerOrder: [UUID] = []

    /// Players ordered according to `playerOrder`; any players not present in `playerOrder` are appended.
    var orderedPlayers: [Player] {
        let map = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        var ordered: [Player] = playerOrder.compactMap { map[$0] }
        for p in players {
            if !playerOrder.contains(p.id) {
                ordered.append(p)
            }
        }
        return ordered
    }

    // Thirteen rounds
    @Relationship(deleteRule: .cascade) var rounds: [Round]
    var currentRoundIndex: Int
    var dealerPlayerIdForNextRound: UUID?

    // Spades configuration + rounds
    var spadesTargetScore: Int
    @Relationship(deleteRule: .cascade) var spadesRounds: [SpadesRound]

    // Hearts configuration + rounds
    var heartsTargetScore: Int
    @Relationship(deleteRule: .cascade) var heartsRounds: [HeartsRound]

    // UNO configuration + rounds
    var unoTargetScore: Int
    @Relationship(deleteRule: .cascade) var unoRounds: [UnoRound]

    // Cabo configuration + rounds
    var caboTargetScore: Int
    @Relationship(deleteRule: .cascade) var caboRounds: [CaboRound]

    init(gameType: GameType, players: [Player]) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.gameTypeRaw = gameType.rawValue
        self.isCompleted = false

        self.players = players
        self.playerOrder = players.map(\.id)

        self.rounds = []
        self.currentRoundIndex = 0
        self.dealerPlayerIdForNextRound = nil

        // Spades defaults
        self.spadesTargetScore = 500
        self.spadesRounds = []

        // Hearts defaults
        self.heartsTargetScore = HeartsRules.defaultTarget
        self.heartsRounds = []

        // UNO defaults
        self.unoTargetScore = UnoRules.defaultTarget
        self.unoRounds = []

        // Cabo defaults
        self.caboTargetScore = CaboRules.defaultTarget
        self.caboRounds = []
    }

    var gameType: GameType { GameType(rawValue: gameTypeRaw) ?? .thirteen }
}
