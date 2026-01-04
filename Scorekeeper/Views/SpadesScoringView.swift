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
    @State private var displayedRoundIndex: Int = 0
    @State private var editingPrevious = false
    @State private var showResults = false

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
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        // round strip (previous rounds + current)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<(roundIndex + 1), id: \.self) { i in
                                    Button {
                                        displayedRoundIndex = i
                                        editingPrevious = false
                                        step = .bids
                                        initDraftIfNeeded()
                                    } label: {
                                        Text(i == roundIndex ? "Next" : "R\(i+1)")
                                            .font(.system(size: 14, weight: i == displayedRoundIndex ? .semibold : .regular, design: .rounded))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(i == displayedRoundIndex ? AppTheme.accent.opacity(0.25) : AppTheme.primary.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        scoreboard

                        if displayedRoundIndex == roundIndex {
                            if step == .bids {
                                bidsStep
                            } else {
                                tricksStep
                            }
                        } else {
                            previousSpadesRoundView
                        }
                    }
                    .padding()
                }
                .onAppear {
                    initDraftIfNeeded()
                    displayedRoundIndex = roundIndex
                }
                .onChange(of: gameOver) { new in if new { showResults = true } }
                .background(
                    NavigationLink(destination: SpadesResultsView(session: session), isActive: $showResults) {
                        EmptyView()
                    }
                    .hidden()
                )
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
                NavigationLink("Results") {
                    SpadesResultsView(session: session)
                }
                .buttonStyle(.bordered)
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

            ForEach(session.orderedPlayers, id: \.id) { p in
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

            ForEach(session.orderedPlayers, id: \.id) { p in
                HStack(spacing: 12) {
                    Text(p.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("0", text: bindingTricks(p.id))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .modifier(DarkTextFieldStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            let totalTricks = session.orderedPlayers.map { Int(tricksDraft[$0.id] ?? "") ?? 0 }.reduce(0, +)

            Text("Total tricks entered: \(totalTricks) (should be 13)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(totalTricks == 13 ? AppTheme.accent : AppTheme.secondary)
                .padding(.top, 4)
        }
    }

    private func initDraftIfNeeded() {
        if bidDraft.isEmpty {
            for p in session.orderedPlayers {
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

        for pid in session.orderedPlayers.map(\.id) {
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

        // Move the UI to the newly-created round immediately
        displayedRoundIndex = roundIndex

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

        // ensure draft/step state shows the next round UI
        step = .bids

        try? modelContext.save()
    }

    private var previousSpadesRoundView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(displayedRoundIndex == roundIndex ? "Next Round" : "Round \(displayedRoundIndex + 1)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Button(editingPrevious ? "Cancel" : "Edit") {
                    if editingPrevious {
                        initDraftIfNeeded()
                    } else {
                        if let r = spadesRoundForIndex(displayedRoundIndex) {
                            // populate drafts
                            for p in session.orderedPlayers {
                                bidDraft[p.id] = String(r.playerEntries[p.id]?.bid ?? 0)
                                tricksDraft[p.id] = String(r.playerEntries[p.id]?.tricks ?? 0)
                                blindNilDraft[p.id] = r.playerEntries[p.id]?.isBlindNil ?? false
                            }
                        }
                    }
                    editingPrevious.toggle()
                }
                .buttonStyle(.bordered)
            }

            ForEach(session.orderedPlayers, id: \.id) { p in
                HStack {
                    Text(p.name)
                    Spacer()
                    if editingPrevious {
                        VStack(spacing: 6) {
                            TextField("Bid", text: Binding(get: { bidDraft[p.id] ?? "" }, set: { bidDraft[p.id] = $0.filter { $0.isNumber } }))
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .modifier(DarkTextFieldStyle())
                            TextField("Tricks", text: Binding(get: { tricksDraft[p.id] ?? "" }, set: { tricksDraft[p.id] = $0.filter { $0.isNumber } }))
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .modifier(DarkTextFieldStyle())
                        }
                    } else {
                        let v = spadesRoundForIndex(displayedRoundIndex)?.playerEntries[p.id]
                        VStack(alignment: .trailing) {
                            Text("Bid: \(v?.bid ?? 0)")
                                .foregroundStyle(AppTheme.secondary)
                            Text("Tricks: \(v?.tricks ?? 0)")
                                .foregroundStyle(AppTheme.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            if editingPrevious {
                Button("Save Changes") {
                    saveEditedSpadesRound()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func spadesRoundForIndex(_ idx: Int) -> SpadesRound? {
        session.spadesRounds.first { $0.index == idx }
    }

    private func saveEditedSpadesRound() {
        guard let i = session.spadesRounds.firstIndex(where: { $0.index == displayedRoundIndex }) else { return }
        var entries: [UUID: SpadesRound.PlayerScores] = [:]
        for pid in session.orderedPlayers.map(\.id) {
            let isBlind = blindNilDraft[pid] ?? false
            let bid = Int(bidDraft[pid] ?? "") ?? 0
            let tricks = Int(tricksDraft[pid] ?? "") ?? 0
            let isNil = (!isBlind && bid == 0)
            entries[pid] = SpadesRound.PlayerScores(bid: bid, isNil: isNil, isBlindNil: isBlind, tricks: tricks)
        }
        session.spadesRounds[i].playerEntries = entries
        session.updatedAt = Date()
        try? modelContext.save()
        editingPrevious = false
    }
}
