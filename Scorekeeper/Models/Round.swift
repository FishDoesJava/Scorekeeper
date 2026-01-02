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

    // Provide a default empty dictionary to help SwiftData migrations
    var scores: [UUID: Int] = [:]
    init(index: Int, label: String, scores: [UUID: Int], dealerForNextRoundId: UUID?) {
        self.id = UUID()
        self.index = index
        self.label = label
        self.scores = scores
        self.dealerForNextRoundId = dealerForNextRoundId
    }

    func score(for playerId: UUID) -> Int {
        scores[playerId] ?? 0
    }
}
