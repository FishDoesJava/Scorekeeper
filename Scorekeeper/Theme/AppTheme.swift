//
//  AppTheme.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

enum AppTheme {
    static let background = Color("Background")
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
}

struct ThemedContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            content.foregroundStyle(AppTheme.primary)
        }
        .tint(AppTheme.accent)
    }
}

struct DarkTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(AppTheme.primary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary.opacity(0.12), lineWidth: 1)
            )
    }
}
