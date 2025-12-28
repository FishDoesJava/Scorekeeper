//
//  Player.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
