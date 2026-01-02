//
//  GamePickerView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

struct GamePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onStarted: (GameSession) -> Void

    var body: some View {
        ThemedContainer {
            NavigationStack {
                List {
                    NavigationLink {
                        NewThirteenSetupView { session in
                            Haptics.success()
                            dismiss()
                            onStarted(session)
                        }
                    } label: {
                        Text(GameType.thirteen.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.background.opacity(0.7))

                    NavigationLink {
                        NewSpadesSetupView { session in
                            Haptics.success()
                            dismiss()
                            onStarted(session)
                        }
                    } label: {
                        Text(GameType.spades.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.background.opacity(0.7))

                    NavigationLink {
                        NewHeartsSetupView { session in
                            Haptics.success()
                            dismiss()
                            onStarted(session)
                        }
                    } label: {
                        Text(GameType.hearts.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.background.opacity(0.7))

                    NavigationLink {
                        NewUnoSetupView { session in
                            Haptics.success()
                            dismiss()
                            onStarted(session)
                        }
                    } label: {
                        Text(GameType.uno.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.background.opacity(0.7))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)

                // Critical: if a parent view disabled the tree, this forces it back on.
                .environment(\.isEnabled, true)

                // Also ensure the accent/tap visuals look active.
                .tint(AppTheme.accent)

                .navigationTitle("Choose Game")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppTheme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            Haptics.tap()
                            dismiss()
                        }
                        .foregroundStyle(AppTheme.accent)
                    }
                }
            }
        }
    }
}
