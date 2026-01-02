//
//  SessionRouteView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/27/25.
//

import SwiftUI
import SwiftData

struct SpadesScoringView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: GameSession

    @State private var step: Step = .bids

    @State private var bidDraft: [UUID: String] = [:]
    @State private var blindNilDraft: [UUID: Bool] = [:]
    @State private var tricksDraft: [UUID: String] = [:]

    enum Step { case bids, tricks }

    private var settings: SpadesEngine.Settings {
        SpadesEngine.Settings(targetScore: session.spadesTargetScore)
    }

    private var roundIndex: Int {
        (session.spadesRounds.map(\.index).max() ?? -1) + 1
    }

    private var teams: ([Player], [Player]) {
        SpadesEngine.teams(session: session)
    }

    private var snapshots: (SpadesEngine.TeamSnapshot, SpadesEngine.TeamSnapshot) {
        SpadesEngine.runningTeamSnapshots(session: session, settings: settings)
    }

    private var gameOver: Bool {
        SpadesEngine.isGameOver(teamA: snapshots.0, teamB: snapshots.1, target: session.spadesTargetScore)
    }

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(spacing: 14) {
                    header
                    scoreboard

                    if step == .bids {
                        bidsStep
                    } else {
                        tricksStep
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .onAppear { initDraftIfNeeded() }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        hideKeyboard()
                        if step == .bids {
                            step = .tricks
                        } else {
                            Haptics.tap()
                            saveSpadesRound()
                            step = .bids
                        }
                    } label: {
                        Text(step == .bids ? "Next: Tricks" : "Save Round")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(gameOver)
                    .opacity(gameOver ? 0.6 : 1.0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { hideKeyboard() }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { hideKeyboard() }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Spades")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text("Target \(session.spadesTargetScore)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            if gameOver {
                Text("Game Over")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var scoreboard: some View {
        HStack(spacing: 12) {
            teamScoreCard(title: "Team A", players: teams.0, score: snapshots.0.score, bags: snapshots.0.bags)
            teamScoreCard(title: "Team B", players: teams.1, score: snapshots.1.score, bags: snapshots.1.bags)
        }
    }

    private func teamScoreCard(title: String, players: [Player], score: Int, bags: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(score)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }

            Text(players.map(\.name).joined(separator: " • "))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary)

            Text("Bags: \(bags)")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary)
        }
        .padding(12)
        .background(AppTheme.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var bidsStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bids")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)

                Text("Tip: A bid of 0 counts as Nil. Use Blind Nil only when you bid Nil before seeing your hand.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondary)
            }

            ForEach(session.players, id: \.id) { p in
                let isBlindNil = blindNilDraft[p.id] ?? false
                let bidInt = Int(bidDraft[p.id] ?? "") ?? 0
                let isNil = (!isBlindNil && bidInt == 0)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        if isBlindNil {
                            Text("Blind Nil")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                        } else if isNil {
                            Text("Nil (bid 0)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(AppTheme.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle(isOn: Binding(
                        get: { blindNilDraft[p.id] ?? false },
                        set: { newVal in
                            blindNilDraft[p.id] = newVal
                            if newVal {
                                // Blind Nil implies a 0 bid; keep the UI consistent.
                                bidDraft[p.id] = ""
                            }
                        }
                    )) {
                        Text("Blind Nil")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.secondary)
                    }
                    .toggleStyle(.switch)
                    .frame(width: 120)

                    TextField("0", text: bindingBid(p.id))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .modifier(DarkTextFieldStyle())
                        .disabled(isBlindNil)
                        .opacity(isBlindNil ? 0.6 : 1.0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            let teamBidA = teams.0.map { Int(bidDraft[$0.id] ?? "") ?? 0 }.reduce(0, +)
            let teamBidB = teams.1.map { Int(bidDraft[$0.id] ?? "") ?? 0 }.reduce(0, +)

            HStack {
                Text("Team A bid: \(teamBidA)")
                Spacer()
                Text("Team B bid: \(teamBidB)")
            }
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(AppTheme.secondary)
            .padding(.top, 4)
        }
    }

    private var tricksStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tricks Taken")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primary)

            ForEach(session.players, id: \.id) { p in
                HStack(spacing: 10) {
                    Text(p.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("0", text: bindingTricks(p.id))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .modifier(DarkTextFieldStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            let totalTricks = session.players.map { Int(tricksDraft[$0.id] ?? "") ?? 0 }.reduce(0, +)

            Text("Total tricks entered: \(totalTricks) (should be 13)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(totalTricks == 13 ? AppTheme.accent : AppTheme.secondary)
                .padding(.top, 4)
        }
    }

    private func initDraftIfNeeded() {
        if bidDraft.isEmpty {
            for p in session.players {
                bidDraft[p.id] = ""
                tricksDraft[p.id] = ""
                blindNilDraft[p.id] = false
            }
        }
    }

    private func bindingBid(_ id: UUID) -> Binding<String> {
        Binding(
            get: { bidDraft[id] ?? "" },
            set: { bidDraft[id] = $0.filter { $0.isNumber } }
        )
    }

    private func bindingTricks(_ id: UUID) -> Binding<String> {
        Binding(
            get: { tricksDraft[id] ?? "" },
            set: { tricksDraft[id] = $0.filter { $0.isNumber } }
        )
    }

    private func saveSpadesRound() {
        guard !session.isCompleted else { return }

        func intClamped(_ s: String?, min lo: Int, max hi: Int) -> Int {
            let v = Int(s ?? "") ?? 0
            return Swift.max(lo, Swift.min(v, hi))
        }

        var entries: [UUID: SpadesRound.PlayerScores] = [:]

        for pid in session.players.map(\.id) {
            let isBlindNil = blindNilDraft[pid] ?? false
            let bid = isBlindNil ? 0 : intClamped(bidDraft[pid], min: 0, max: 13)
            let tricks = intClamped(tricksDraft[pid], min: 0, max: 13)
            let isNil = (!isBlindNil && bid == 0)
            entries[pid] = SpadesRound.PlayerScores(
                bid: bid,
                isNil: isNil,
                isBlindNil: isBlindNil,
                tricks: tricks
            )
        }

        let r = SpadesRound(index: roundIndex, playerEntries: entries)

        session.spadesRounds.append(r)
        session.updatedAt = Date()

        let snap = SpadesEngine.runningTeamSnapshots(session: session, settings: settings)
        if SpadesEngine.isGameOver(teamA: snap.0, teamB: snap.1, target: session.spadesTargetScore) {
            session.isCompleted = true
        }

        // Reset for next round
        for pid in entries.keys {
            bidDraft[pid] = ""
            tricksDraft[pid] = ""
            blindNilDraft[pid] = false
        }

        try? modelContext.save()
    }
}
