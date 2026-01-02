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

    private var roundIndex: Int { session.currentRoundIndex }
    private var roundLabel: String { ThirteenRules.roundLabels[min(roundIndex, 12)] }
    private var totals: [UUID: Int] { ThirteenEngine.runningTotals(session: session) }

    /// Dealer for the CURRENT round (this is what we display).
    private var currentDealerId: UUID? { session.dealerPlayerIdForNextRound }

    var body: some View {
        ThemedContainer {
            NavigationStack {
                VStack(spacing: 14) {
                    header
                    roundStrip
                    dealerRow
                    scoreEntryList

                    Spacer(minLength: 0)
                }
                .padding()
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
                    // Provide a keyboard accessory "Done"
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { hideKeyboard() }
                        }
                    }
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
                }
            }
        }
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
                    Text(label)
                        .font(.system(size: 16, weight: i == roundIndex ? .semibold : .regular, design: .rounded))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(i == roundIndex ? AppTheme.accent.opacity(0.25) : AppTheme.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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

        let playerIds = session.players.map(\.id)
        let scoreValues = playerIds.map { scores[$0] ?? 0 }

        let round = Round(
            index: session.currentRoundIndex,
            label: roundLabel,
            playerIds: playerIds,
            scoreValues: scoreValues,
            dealerForNextRoundId: nextDealer
        )

        session.rounds.append(round)
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

        try? modelContext.save()
    }
}
