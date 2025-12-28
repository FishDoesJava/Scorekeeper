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

    // parallel arrays keyed by playerIds index
    var playerIds: [UUID]

    var bidValues: [Int]         // 0-13
    var nilFlags: [Bool]
    var blindNilFlags: [Bool]

    var tricksValues: [Int]      // 0-13, sum to 13 (we won't hard-enforce, but UI nudges)

    init(index: Int,
         playerIds: [UUID],
         bidValues: [Int],
         nilFlags: [Bool],
         blindNilFlags: [Bool],
         tricksValues: [Int]) {
        self.id = UUID()
        self.index = index
        self.createdAt = Date()
        self.playerIds = playerIds
        self.bidValues = bidValues
        self.nilFlags = nilFlags
        self.blindNilFlags = blindNilFlags
        self.tricksValues = tricksValues
    }

    func idx(for playerId: UUID) -> Int? {
        playerIds.firstIndex(of: playerId)
    }

    func bid(for playerId: UUID) -> Int {
        guard let i = idx(for: playerId), bidValues.indices.contains(i) else { return 0 }
        return bidValues[i]
    }

    func isNil(for playerId: UUID) -> Bool {
        guard let i = idx(for: playerId), nilFlags.indices.contains(i) else { return false }
        return nilFlags[i]
    }

    func isBlindNil(for playerId: UUID) -> Bool {
        guard let i = idx(for: playerId), blindNilFlags.indices.contains(i) else { return false }
        return blindNilFlags[i]
    }

    func tricks(for playerId: UUID) -> Int {
        guard let i = idx(for: playerId), tricksValues.indices.contains(i) else { return 0 }
        return tricksValues[i]
    }
}
