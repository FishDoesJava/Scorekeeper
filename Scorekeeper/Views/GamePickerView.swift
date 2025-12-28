//
//  GamePickerView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

struct GamePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onStarted: (UUID) -> Void

    var body: some View {
        ThemedContainer {
            NavigationStack {
                List {
                    NavigationLink {
                        NewThirteenSetupView { id in
                            Haptics.success()
                            dismiss()
                            onStarted(id)
                        }
                    } label: {
                        Text(GameType.thirteen.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.black.opacity(0.7))

                    NavigationLink {
                        NewSpadesSetupView { id in
                            Haptics.success()
                            dismiss()
                            onStarted(id)
                        }
                    } label: {
                        Text(GameType.spades.menuTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.black.opacity(0.7))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.black)

                // Critical: if a parent view disabled the tree, this forces it back on.
                .environment(\.isEnabled, true)

                // Also ensure the accent/tap visuals look active.
                .tint(AppTheme.accent)

                .navigationTitle("Choose Game")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.black, for: .navigationBar)
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
