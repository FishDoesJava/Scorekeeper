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

    // Thirteen rounds
    @Relationship(deleteRule: .cascade) var rounds: [Round]
    var currentRoundIndex: Int
    var dealerPlayerIdForNextRound: UUID?

    // Spades configuration + rounds
    var spadesTargetScore: Int
    @Relationship(deleteRule: .cascade) var spadesRounds: [SpadesRound]

    init(gameType: GameType, players: [Player]) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.gameTypeRaw = gameType.rawValue
        self.isCompleted = false

        self.players = players

        self.rounds = []
        self.currentRoundIndex = 0
        self.dealerPlayerIdForNextRound = nil

        // Spades defaults
        self.spadesTargetScore = 500
        self.spadesRounds = []
    }

    var gameType: GameType { GameType(rawValue: gameTypeRaw) ?? .thirteen }
}
