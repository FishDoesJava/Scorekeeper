//
//  DealerOverrideSheet.swift
//  Scorekeeper
//
//  Created by Grant Fish on 12/25/25.
//

import SwiftUI

struct DealerOverrideSheet: View {
    @Environment(\.dismiss) private var dismiss

    let players: [Player]
    let currentlySelected: UUID?
    let onSelect: (UUID) -> Void

    var body: some View {
        ThemedContainer {
            NavigationStack {
                List {
                    ForEach(players, id: \.id) { p in
                        Button {
                            onSelect(p.id)
                            dismiss()
                        } label: {
                            HStack {
                                Text(p.name)
                                Spacer()
                                if currentlySelected == p.id {
                                    Text("Selected")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .listRowBackground(Color.black.opacity(0.7))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .navigationTitle("Dealer")
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
    }
}
