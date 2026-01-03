//
//  ThirteenScoringView.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI
import SwiftData

struct ThirteenScoringView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: GameSession

    @State private var scoreDraft: [UUID: String] = [:]
    @State private var showDealerPicker = false
    @State private var totals: [UUID: Int] = [:]
    @State private var displayedRoundIndex: Int = 0
    @State private var editingPrevious = false
    @State private var showResults = false

    private var roundIndex: Int { session.currentRoundIndex }
    private var roundLabel: String { ThirteenRules.roundLabels[min(roundIndex, 12)] }

    /// Dealer for the CURRENT round (this is what we display).
    private var currentDealerId: UUID? { session.dealerPlayerIdForNextRound }

    var body: some View {
        ThemedContainer {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        roundStrip
                        dealerRow
                        if displayedRoundIndex == session.currentRoundIndex && !editingPrevious {
                            scoreEntryList
                        } else {
                            previousRoundView
                        }
                    }
                    .padding()
                }
                // Keep the save button visible above the keyboard
                .safeAreaInset(edge: .bottom) {
                    Button {
                        hideKeyboard()
                        Haptics.tap()
                        saveRound()
                    } label: {
                        Text(roundIndex < 12 ? "Save Round \(roundLabel)" : "Finish (Save K)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                // Dismiss keyboard by dragging
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { hideKeyboard() }
                .sheet(isPresented: $showDealerPicker) {
                    DealerOverrideSheet(
                        players: session.players,
                        currentlySelected: currentDealerId,
                        onSelect: { chosenId in
                            session.dealerPlayerIdForNextRound = chosenId
                            session.updatedAt = Date()
                            try? modelContext.save()
                        }
                    )
                    .preferredColorScheme(.dark)
                }
                .onAppear {
                    initializeDraftIfNeeded()
                    ensureInitialDealerIfNeeded()
                    refreshTotals()
                    displayedRoundIndex = session.currentRoundIndex
                }
                .onChange(of: session.rounds.count) { _ in
                    refreshTotals()
                }
                .onChange(of: session.isCompleted) { new in
                    if new {
                        showResults = true
                    }
                }
                // Hidden navigation link to auto-open results
                .background(
                    NavigationLink(destination: FinalResultsView(session: session), isActive: $showResults) {
                        EmptyView()
                    }
                    .hidden()
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { hideKeyboard() }
                    }
                }
            }
        }
    }

    private var previousRoundView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Round \(ThirteenRules.roundLabels[displayedRoundIndex])")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Button(editingPrevious ? "Cancel" : "Edit") {
                    if editingPrevious {
                        // cancel edits
                        initializeDraftIfNeeded()
                    } else {
                        // populate draft from selected round
                        if let r = roundForIndex(displayedRoundIndex) {
                            for p in session.players { scoreDraft[p.id] = String(r.scores[p.id] ?? 0) }
                        }
                    }
                    editingPrevious.toggle()
                }
                .buttonStyle(.bordered)
            }

            ForEach(session.players, id: \.id) { p in
                HStack {
                    Text(p.name)
                    Spacer()
                    if editingPrevious {
                        TextField("0", text: bindingForPlayer(p.id))
                            .keyboardType(.numberPad)
                            .frame(width: 90)
                            .modifier(DarkTextFieldStyle())
                    } else {
                        Text("\(roundForIndex(displayedRoundIndex)?.scores[p.id] ?? 0)")
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            if editingPrevious {
                Button("Save Changes") {
                    saveEditedRound()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func roundForIndex(_ idx: Int) -> Round? {
        session.rounds.first { $0.index == idx }
    }

    private func saveEditedRound() {
        guard let rIndex = session.rounds.firstIndex(where: { $0.index == displayedRoundIndex }) else { return }
        var newScores: [UUID: Int] = [:]
        for p in session.players { newScores[p.id] = Int(scoreDraft[p.id] ?? "") ?? 0 }
        session.rounds[rIndex].scores = newScores
        session.updatedAt = Date()
        try? modelContext.save()
        editingPrevious = false
        refreshTotals()
    }

    // MARK: - UI

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Thirteen")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text(session.isCompleted ? "Completed" : "Round \(roundLabel)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            if session.isCompleted {
                NavigationLink("Results") {
                    FinalResultsView(session: session)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var roundStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(ThirteenRules.roundLabels.enumerated()), id: \.offset) { i, label in
                    Button {
                        displayedRoundIndex = i
                        editingPrevious = false
                    } label: {
                        Text(label)
                            .font(.system(size: 16, weight: i == displayedRoundIndex ? .semibold : .regular, design: .rounded))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(i == displayedRoundIndex ? AppTheme.accent.opacity(0.25) : AppTheme.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dealerRow: some View {
        HStack(spacing: 10) {
            Text("Dealer:")
                .foregroundStyle(AppTheme.secondary)

            Text(dealerName(currentDealerId))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(AppTheme.accent.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    hideKeyboard()
                    showDealerPicker = true
                }

            Spacer()

            Text("Tap to change")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary.opacity(0.75))
        }
    }

    private var scoreEntryList: some View {
        VStack(spacing: 10) {
            ForEach(session.players, id: \.id) { p in
                HStack(spacing: 12) {
                    Text(p.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Total \(totals[p.id, default: 0])")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.secondary)

                    TextField("0", text: bindingForPlayer(p.id))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .modifier(DarkTextFieldStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(p.id == currentDealerId ? AppTheme.accent.opacity(0.85) : Color.clear, lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Draft / Bindings

    private func initializeDraftIfNeeded() {
        if scoreDraft.isEmpty {
            for p in session.players { scoreDraft[p.id] = "" } // empty UX, defaults to 0 on save
        }
    }

    private func bindingForPlayer(_ id: UUID) -> Binding<String> {
        Binding(
            get: { scoreDraft[id] ?? "" },
            set: { scoreDraft[id] = $0.filter { $0.isNumber } }
        )
    }

    private func dealerName(_ id: UUID?) -> String {
        guard let id, let p = session.players.first(where: { $0.id == id }) else { return "—" }
        return p.name
    }

    private func ensureInitialDealerIfNeeded() {
        guard session.dealerPlayerIdForNextRound == nil else { return }
        guard !session.players.isEmpty else { return }
        session.dealerPlayerIdForNextRound = session.players.randomElement()?.id
        session.updatedAt = Date()
        try? modelContext.save()
    }

    private func refreshTotals() {
        totals = ThirteenEngine.runningTotals(session: session)
    }

    // MARK: - Save Logic

    private func saveRound() {
        guard !session.isCompleted else { return }

        // Parse blanks -> 0; clamp 0...9999
        var scores: [UUID: Int] = [:]
        for p in session.players {
            let raw = scoreDraft[p.id] ?? ""
            let val = Int(raw) ?? 0
            scores[p.id] = min(max(val, 0), 9999)
        }

        // Compute NEXT round dealer based on this round scores
        let nextDealer = ThirteenEngine.pickDealerForNextRound(session: session, roundScores: scores)

        let round = Round(
            index: session.currentRoundIndex,
            label: roundLabel,
            scores: scores,
            dealerForNextRoundId: nextDealer
        )

        session.rounds.append(round)
        refreshTotals()
        session.updatedAt = Date()

        if session.currentRoundIndex >= 12 {
            session.isCompleted = true
        } else {
            session.currentRoundIndex += 1
            // NEXT dealer becomes CURRENT dealer for the next round
            session.dealerPlayerIdForNextRound = nextDealer

            // reset entries to empty (defaults to 0 on save)
            for p in session.players { scoreDraft[p.id] = "" }
        }

        // Ensure UI shows the newly-created round immediately
        displayedRoundIndex = session.currentRoundIndex

        try? modelContext.save()
    }
}
