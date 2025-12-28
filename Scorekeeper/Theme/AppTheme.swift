//
//  AppTheme.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

enum AppTheme {
    static let bg = Color.black
    static let fg = Color.white
    static let accent = Color(red: 0.20, green: 0.90, blue: 0.70) // mint
}

struct ThemedContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            content.foregroundStyle(AppTheme.fg)
        }
        .tint(AppTheme.accent)
    }
}

struct DarkTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.fg) // white text
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.10)) // dark field
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
