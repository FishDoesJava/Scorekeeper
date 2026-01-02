//
//  SpadesRound.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class SpadesRound {
    var id: UUID
    var index: Int
    var createdAt: Date

    struct PlayerScores: Codable, Hashable {
        var bid: Int
        var isNil: Bool
        var isBlindNil: Bool
        var tricks: Int
    }

    // keyed by player id
    var playerEntries: [UUID: PlayerScores]

    init(index: Int,
         playerEntries: [UUID: PlayerScores]) {
        self.id = UUID()
        self.index = index
        self.createdAt = Date()
        self.playerEntries = playerEntries
    }

    func bid(for playerId: UUID) -> Int {
        playerEntries[playerId]?.bid ?? 0
    }

    func isNil(for playerId: UUID) -> Bool {
        playerEntries[playerId]?.isNil ?? false
    }

    func isBlindNil(for playerId: UUID) -> Bool {
        playerEntries[playerId]?.isBlindNil ?? false
    }

    func tricks(for playerId: UUID) -> Int {
        playerEntries[playerId]?.tricks ?? 0
    }
}
