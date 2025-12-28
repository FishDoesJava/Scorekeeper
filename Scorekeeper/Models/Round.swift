//
//  Round.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import Foundation
import SwiftData

@Model
final class Round {
    var id: UUID
    var index: Int
    var label: String
    var dealerForNextRoundId: UUID?

    var playerIds: [UUID]
    var scoreValues: [Int]

    init(index: Int, label: String, playerIds: [UUID], scoreValues: [Int], dealerForNextRoundId: UUID?) {
        self.id = UUID()
        self.index = index
        self.label = label
        self.playerIds = playerIds
        self.scoreValues = scoreValues
        self.dealerForNextRoundId = dealerForNextRoundId
    }

    func score(for playerId: UUID) -> Int {
        guard let i = playerIds.firstIndex(of: playerId) else { return 0 }
        return scoreValues.indices.contains(i) ? scoreValues[i] : 0
    }
}
