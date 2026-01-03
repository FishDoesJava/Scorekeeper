//
//  UnoScoringView.swift
//  Scorekeeper
//
//  Created by OpenAI on 02/11/25.
//

import SwiftUI
import SwiftData

struct UnoScoringView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: GameSession

    @State private var scoreDraft: [UUID: String] = [:]
    @State private var displayedRoundIndex: Int = 0
    @State private var editingPrevious = false
    @State private var showResults = false

    private var nextRoundIndex: Int {
        (session.unoRounds.map(\.index).max() ?? -1) + 1
    }

    private var totals: [UUID: Int] {
        UnoEngine.runningTotals(session: session)
    }

    private var gameOver: Bool {
        UnoEngine.isGameOver(totals: totals, target: session.unoTargetScore)
    }

    var body: some View {
        ThemedContainer {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        roundStrip
                        totalsList

                        if displayedRoundIndex == nextRoundIndex {
                            entryList
                        } else {
                            previousRoundView
                        }
                    }
                    .padding()
                }
                .onAppear {
                    initializeDraftIfNeeded()
                    displayedRoundIndex = nextRoundIndex
                    if session.isCompleted {
                        showResults = true
                    }
                }
                .onChange(of: gameOver) { new in
                    if new {
                        session.isCompleted = true
                        showResults = true
                    }
                }
                .background(
                    NavigationLink(destination: UnoResultsView(session: session), isActive: $showResults) {
                        EmptyView()
                    }
                    .hidden()
                )
                .safeAreaInset(edge: .bottom) {
                    Button {
                        hideKeyboard()
                        if displayedRoundIndex == nextRoundIndex {
                            saveRound()
                        }
                    } label: {
                        Text(displayedRoundIndex == nextRoundIndex ? "Save Round" : "Viewing Round")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(displayedRoundIndex != nextRoundIndex || gameOver)
                    .opacity((displayedRoundIndex != nextRoundIndex || gameOver) ? 0.6 : 1.0)
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
                Text("UNO")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text("Target \(session.unoTargetScore)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            if gameOver {
                NavigationLink("Results") {
                    UnoResultsView(session: session)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var roundStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<(nextRoundIndex + 1), id: \.self) { i in
                    Button {
                        displayedRoundIndex = i
                        editingPrevious = false
                        initializeDraftIfNeeded()
                    } label: {
                        Text(i == nextRoundIndex ? "Next" : "R\(i+1)")
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
    }

    private var totalsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Totals")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                if gameOver {
                    Text("Game over")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            ForEach(session.players, id: \.id) { p in
                HStack {
                    Text(p.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Text("\(totals[p.id, default: 0])")
                        .foregroundStyle(AppTheme.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(AppTheme.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var entryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Round \(nextRoundIndex + 1) Points")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text("Enter points earned by each player this round. First to reach the target wins.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.secondary)

            ForEach(session.players, id: \.id) { p in
                HStack(spacing: 12) {
                    Text(p.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("0", text: bindingForPlayer(p.id))
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
        }
    }

    private var previousRoundView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Round \(displayedRoundIndex + 1)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Button(editingPrevious ? "Cancel" : "Edit") {
                    if editingPrevious {
                        initializeDraftIfNeeded()
                    } else if let r = roundForIndex(displayedRoundIndex) {
                        for p in session.players {
                            scoreDraft[p.id] = String(r.score(for: p.id))
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
                            .frame(width: 80)
                            .modifier(DarkTextFieldStyle())
                    } else {
                        Text("\(roundForIndex(displayedRoundIndex)?.score(for: p.id) ?? 0)")
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

    // MARK: - Draft helpers

    private func initializeDraftIfNeeded() {
        for p in session.players where scoreDraft[p.id] == nil {
            scoreDraft[p.id] = ""
        }
    }

    private func bindingForPlayer(_ id: UUID) -> Binding<String> {
        Binding(
            get: { scoreDraft[id] ?? "" },
            set: { scoreDraft[id] = $0 }
        )
    }

    private func roundForIndex(_ idx: Int) -> UnoRound? {
        session.unoRounds.first { $0.index == idx }
    }

    // MARK: - Save logic

    private func saveRound() {
        var scores: [UUID: Int] = [:]
        for p in session.players {
            let value = Int(scoreDraft[p.id] ?? "") ?? 0
            scores[p.id] = max(0, min(2000, value))
            scoreDraft[p.id] = ""
        }

        let newRound = UnoRound(index: nextRoundIndex, scores: scores)
        session.unoRounds.append(newRound)
        session.updatedAt = Date()
        session.isCompleted = gameOverAfterAdding(round: scores)
        try? modelContext.save()

        displayedRoundIndex = nextRoundIndex
    }

    private func gameOverAfterAdding(round: [UUID: Int]) -> Bool {
        var newTotals = totals
        for (pid, val) in round {
            newTotals[pid, default: 0] += val
        }
        return UnoEngine.isGameOver(totals: newTotals, target: session.unoTargetScore)
    }

    private func saveEditedRound() {
        guard let index = session.unoRounds.firstIndex(where: { $0.index == displayedRoundIndex }) else { return }
        var scores: [UUID: Int] = [:]
        for p in session.players {
            scores[p.id] = max(0, min(2000, Int(scoreDraft[p.id] ?? "") ?? 0))
        }
        session.unoRounds[index].scores = scores
        session.updatedAt = Date()
        session.isCompleted = UnoEngine.isGameOver(totals: totals, target: session.unoTargetScore)
        try? modelContext.save()
        editingPrevious = false
    }
}
