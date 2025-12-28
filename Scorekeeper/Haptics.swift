//
//  Haptics.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import Foundation

#if canImport(UIKit)
import UIKit

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
#else
enum Haptics {
    static func tap() {}
    static func success() {}
    static func warning() {}
    static func error() {}
}
#endif
