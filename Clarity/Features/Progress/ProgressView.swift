import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var profileStore = UserProfileStore()
    @State private var showPortraitEditor = false

    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    @AppStorage("wisdom_last_done_day_key")
    private var wisdomLastDoneDayKey: String = ""

    @AppStorage("compassion_last_done_day_key")
    private var compassionLastDoneDayKey: String = ""

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

    private var dailyUnitCount: Int {
        let r = Set(reflectCompletions.map(\.dayKey))
        let f = Set(focusCompletions.map(\.dayKey))
        let p = Set(practiceCompletions.map(\.dayKey))
        return r.intersection(f).intersection(p).count
    }

    private var ringOpenCount: Int {
        let total = max(0, dailyUnitCount)
        if total == 0 { return 0 }
        let mod = total % 27
        return mod == 0 ? 27 : mod
    }

    private var layersCompleted: Int {
        max(0, dailyUnitCount) / 27
    }

    private var todayKey: String {
        Date().dayKey()
    }

    private var fullPracticeUnitToday: Bool {
        let r = Set(reflectCompletions.map(\.dayKey))
        let f = Set(focusCompletions.map(\.dayKey))
        let p = Set(practiceCompletions.map(\.dayKey))
        return r.contains(todayKey) && f.contains(todayKey) && p.contains(todayKey)
    }

    private var didWisdomToday: Bool {
        wisdomLastDoneDayKey == todayKey
    }

    private var didCompassionToday: Bool {
        compassionLastDoneDayKey == todayKey
    }

    private var overlayPartialOnLastOpenBead: Bool {
        fullPracticeUnitToday && (didWisdomToday || didCompassionToday)
    }

    var body: some View {
        VStack(spacing: 8) {
            Mala27View(
                openCount: ringOpenCount,
                didWisdomToday: didWisdomToday,
                didCompassionToday: didCompassionToday,
                overlayPartialOnLastOpenBead: overlayPartialOnLastOpenBead,
                layersCompleted: layersCompleted,
                portraitRecipe: profileStore.recipe,
                pulseCentre: false,
                onPortraitTap: { showPortraitEditor = true }
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 28)

            QuarterMalaCountersView(rounds: layersCompleted, visibleRows: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)

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
