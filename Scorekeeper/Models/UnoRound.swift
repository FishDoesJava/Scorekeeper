//
//  UnoRound.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class UnoRound {
    var id: UUID
    var index: Int
    var createdAt: Date
    var scores: [UUID: Int]

    init(index: Int, scores: [UUID: Int]) {
        self.id = UUID()
        self.index = index
        self.createdAt = Date()
        self.scores = scores
    }

    func score(for playerId: UUID) -> Int {
        scores[playerId] ?? 0
    }
}
