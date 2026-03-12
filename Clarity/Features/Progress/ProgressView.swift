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
        VStack(spacing: 18) {
            Mala27View(
                openCount: ringOpenCount,
                layersCompleted: layersCompleted,
                portraitRecipe: profileStore.recipe,
                pulseCentre: false,
                onPortraitTap: { showPortraitEditor = true }
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 28)

            Text("\(ringOpenCount) of 27")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Quarter Malas completed")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                QuarterMalaCountersView(rounds: layersCompleted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
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
