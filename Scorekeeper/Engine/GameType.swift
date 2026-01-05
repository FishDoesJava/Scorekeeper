import Foundation

enum GameType: String, Codable, CaseIterable {
    case thirteen = "Thirteen"
    case spades = "Spades"
    case hearts = "Hearts"
    case uno = "UNO"
    case cabo = "Cabo"

    var menuTitle: String {
        switch self {
        case .thirteen: return "🃏 Thirteen"
        case .spades:   return "♠️ Spades"
        case .hearts:   return "♥️ Hearts"
        case .uno:      return "🔴 UNO"
        case .cabo:     return "🧠 Cabo"
        }
    }
}

struct ThirteenRules {
    static let roundLabels: [String] = ["A","2","3","4","5","6","7","8","9","T","J","Q","K"]
    static let minPlayers = 2
    static let maxPlayers = 8
}

struct HeartsRules {
    static let minPlayers = 3
    static let maxPlayers = 6
    static let defaultTarget = 100
}

struct UnoRules {
    static let minPlayers = 2
    static let maxPlayers = 10
    static let defaultTarget = 500
}

struct CaboRules {
    static let minPlayers = 2
    static let maxPlayers = 6
    static let defaultTarget = 100
}
