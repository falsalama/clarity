// Clarity/Features/Progress/ProgressView.swift

import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var profileStore = UserProfileStore()
    @State private var showPortraitEditor = false

    // Legacy components (used to derive “practice unit” days)
    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    init() {
        _reflectCompletions = Query(
            sort: [SortDescriptor(\ReflectCompletionEntity.completedAt, order: .reverse)]
        )

        _focusCompletions = Query(
            sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)]
        )

        _practiceCompletions = Query(
            sort: [SortDescriptor(\PracticeCompletionEntity.completedAt, order: .reverse)]
        )
    }

    /// A “daily unit” exists only when Reflect + View + Practice are all completed on the same dayKey.
    private var dailyUnitCount: Int {
        let r = Set(reflectCompletions.map(\.dayKey))
        let f = Set(focusCompletions.map(\.dayKey))
        let p = Set(practiceCompletions.map(\.dayKey))
        return r.intersection(f).intersection(p).count
    }

    /// 0...27 beads shown for the current ring.
    private var ringOpenCount: Int {
        let total = max(0, dailyUnitCount)
        if total == 0 { return 0 }
        let mod = total % 27
        return mod == 0 ? 27 : mod
    }

    private var layersCompleted: Int {
        max(0, dailyUnitCount) / 27
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Mala27View(
                    openCount: ringOpenCount,
                    layersCompleted: layersCompleted,
                    portraitRecipe: profileStore.recipe,
                    pulseCentre: false,
                    onPortraitTap: { showPortraitEditor = true }
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 42)

                // Single line only (no extra bracket count)
                Text("\(ringOpenCount) of 27 complete")
                    .font(.title2.weight(.semibold))

                HStack(spacing: 10) {
                    Text("Layers completed: \(layersCompleted)")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    TibetanLayerCountersView(layers: layersCompleted)
                }

                Spacer(minLength: 10)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPortraitEditor, onDismiss: {
            profileStore.attach(modelContext: modelContext)
        }) {
            NavigationStack { PortraitEditorView() }
        }
        .onAppear {
            profileStore.attach(modelContext: modelContext)
        }
    }
}
