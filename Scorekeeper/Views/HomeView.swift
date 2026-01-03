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
    @State private var sessionCache: [UUID: GameSession] = [:]
    @State private var selectedTab: HomeTab = .games
    @Namespace private var buttonNamespace

    var body: some View {
        TabView(selection: $selectedTab) {
            gamesTab
                .tabItem {
                    Label("My games", systemImage: "house.fill")
                }
                .tag(HomeTab.games)

            PlaceholderTabView(
                title: "Players",
                message: "Player management is coming soon.",
                systemImage: "person.2.fill"
            )
            .tabItem {
                Label("Players", systemImage: "person.2.fill")
            }
            .tag(HomeTab.players)

            PlaceholderTabView(
                title: "Stats",
                message: "See your stats in a future update.",
                systemImage: "chart.bar.fill"
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(HomeTab.stats)
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: showNewGameButton)
    }

    private var showNewGameButton: Bool {
        activeSessionID == nil && !showGamePicker
    }

    private var gamesTab: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    logoHeader

                    List {
                        Section {
                            if sessions.isEmpty {
                                emptyStateRow
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                    .listRowBackground(AppTheme.background)
                                    .listRowSeparator(.hidden)
                            } else {
                                ForEach(sessions) { s in
                                    NavigationLink(
                                        tag: s.id,
                                        selection: $activeSessionID
                                    ) {
                                        SessionRouteView(id: s.id, initialSession: s)
                                            .onDisappear { activeSessionID = nil }
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
                    .safeAreaPadding(.bottom, showNewGameButton ? 96 : 0)
                }
            }
            .sheet(isPresented: $showGamePicker) {
                GamePickerView { session in
                    showGamePicker = false
                    sessionCache[session.id] = session
                    print("HomeView: got started session id=\(session.id); cache contains: \(sessionCache.keys)")
                    DispatchQueue.main.async {
                        activeSessionID = session.id
                    }
                }
                .preferredColorScheme(.dark)
            }
            .navigationDestination(item: $activeSessionID) { id in
                SessionRouteView(id: id, initialSession: sessionCache[id] ?? sessions.first(where: { $0.id == id }))
                    .onDisappear { activeSessionID = nil }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showNewGameButton {
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
                .padding(.bottom, 12)
                .matchedGeometryEffect(id: "newGameButton", in: buttonNamespace)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
    }

    private var logoHeader: some View {
        VStack(spacing: 10) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .padding(.top, 14)

            Text("Welcome Back!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.background)
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
        GameType(rawValue: session.gameTypeRaw)?.menuTitle ?? session.gameTypeRaw
    }

    private func subtitle(for session: GameSession) -> String {
        let players = session.players.map(\.name)
        if players.isEmpty { return "Players not found" }
        if players.count <= 3 { return players.joined(separator: " • ") }
        return players.prefix(3).joined(separator: " • ") + " • +\(players.count - 3)"
    }
}

private enum HomeTab: Hashable {
    case games
    case players
    case stats
}

private struct PlaceholderTabView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.bottom, 4)

                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)

                Text(message)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .preferredColorScheme(.dark)
    }
}
