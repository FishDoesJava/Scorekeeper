//
//  HomeView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

//
//  HomeView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSession.updatedAt, order: .reverse) private var sessions: [GameSession]

    @State private var showGamePicker = false
    @State private var activeSessionID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    Section {
                        Text("Scorekeeper")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.top, 6)
                            .padding(.bottom, 4)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(AppTheme.background)
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        if sessions.isEmpty {
                            emptyStateRow
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .listRowBackground(AppTheme.background)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(sessions) { s in
                                NavigationLink {
                                    SessionRouteView(id: s.id)
                                } label: {
                                    sessionCard(s)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(AppTheme.background)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteSessions)
                        }
                    } header: {
                        Text("History")
                            .foregroundStyle(AppTheme.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)

                VStack {
                    Spacer()
                    Button {
                        Haptics.tap()
                        showGamePicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                            Text("New Game")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.primary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .shadow(radius: 18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
            .sheet(isPresented: $showGamePicker) {
                GamePickerView { newId in
                    showGamePicker = false
                    DispatchQueue.main.async {
                        activeSessionID = newId
                    }
                }
                .preferredColorScheme(.dark)
            }
            .navigationDestination(item: $activeSessionID) { id in
                SessionRouteView(id: id)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyStateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No games yet.")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
            Text("Tap “New Game” to start.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary)
        }
        .padding(16)
        .background(AppTheme.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func sessionCard(_ s: GameSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayTitle(for: s))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)

                Spacer()

                Text(s.isCompleted ? "Completed" : "In progress")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(s.isCompleted ? AppTheme.secondary : AppTheme.accent)
            }

            Text(subtitle(for: s))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary)

            // Added: show when the game was started (created)
            Text(s.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary.opacity(0.8))
        }
        .padding(14)
        .background(AppTheme.primary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func deleteSessions(at offsets: IndexSet) {
        Haptics.tap()
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }

    private func displayTitle(for session: GameSession) -> String {
        if let gt = GameType(rawValue: session.gameTypeRaw) { return gt.menuTitle }
        if session.gameTypeRaw == "13" { return "🃏 Thirteen" }
        if session.gameTypeRaw == "Thirteen" { return "🃏 Thirteen" }
        if session.gameTypeRaw == "Spades" { return "♠️ Spades" }
        return session.gameTypeRaw
    }

    private func subtitle(for session: GameSession) -> String {
        let players = session.players.map(\.name)
        if players.isEmpty { return "Players not found" }
        if players.count <= 3 { return players.joined(separator: " • ") }
        return players.prefix(3).joined(separator: " • ") + " • +\(players.count - 3)"
    }
}
