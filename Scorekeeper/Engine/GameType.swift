//
//  GameType.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import Foundation

enum GameType: String, Codable, CaseIterable {
    case thirteen = "Thirteen"
    case spades = "Spades"

    var menuTitle: String {
        switch self {
        case .thirteen: return "🃏 Thirteen"
        case .spades:   return "♠️ Spades"
        }
    }
}

struct ThirteenRules {
    static let roundLabels: [String] = ["A","2","3","4","5","6","7","8","9","T","J","Q","K"]
    static let minPlayers = 2
    static let maxPlayers = 8
}
