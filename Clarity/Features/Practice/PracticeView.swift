// PracticeView.swift

import SwiftUI
import SwiftData

/// PracticeView (v2)
/// - One small practice at a time.
/// - Deterministic: advances one step per day *only after* the user marks Done.
/// - Lock: after Done, the practice does not change until the next day.
/// - Uses PracticeProgramStateEntity (singleton) to future-proof progression (modules/routes later).
struct PracticeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeSurface: HomeSurfaceStore

    // MARK: - “Subtitle under title”

    @AppStorage("PracticeSubtitleSeenCount") private var practiceSubtitleSeenCount = 0
    @State private var countedThisAppear = false
    private let practiceSubtitleShowLimit = 3

    private var shouldShowPracticeSubtitle: Bool {
        practiceSubtitleSeenCount < practiceSubtitleShowLimit
    }

    private var practiceSubtitleText: String? {
        guard shouldShowPracticeSubtitle else { return nil }
        let server = homeSurface.manifest?.practiceSubtitle?.nilIfBlank
        return server ?? "A tiny exercise you can do anywhere."
    }

    // MARK: - Data

    @Query private var completedTurns: [TurnEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    // Singleton program state row (id == "singleton")
    @Query(
        filter: #Predicate<PracticeProgramStateEntity> { $0.id == "singleton" }
    )
    private var programStates: [PracticeProgramStateEntity]

    // MARK: - Practice list (v1 seed)

    private let items: [PracticeItem] = [
        PracticeItem(
            title: "Three breaths",
            body: """
Take three natural breaths.
Nothing to fix. Nothing to achieve.
Just notice the next inhale, then the next exhale.
"""
        ),
        PracticeItem(
            title: "Soften the jaw",
            body: """
Let the jaw unclench.
Let the tongue rest.
Notice what changes when the face stops bracing.
"""
        ),
        PracticeItem(
            title: "Name the feeling",
            body: """
Silently name what is most present.
“Pressure”, “tired”, “open”, “restless”, “fine”.
No analysis. Just a clean label.
"""
        )
    ]

    // Expand/collapse body
    @State private var isExpanded = true

    // MARK: - Init

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )

        _practiceCompletions = Query(
            sort: [SortDescriptor(\PracticeCompletionEntity.completedAt, order: .reverse)]
        )
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                practiceCard
                optionalHint
                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Practice")
                        .font(.headline)
                    if let s = practiceSubtitleText {
                        Text(s)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                achievementsLink
            }
        }
        .onAppear {
            ensureProgramStateExists()
            applyDailyAdvanceIfNeeded()

            if shouldShowPracticeSubtitle && !countedThisAppear {
                practiceSubtitleSeenCount += 1
                countedThisAppear = true
            }
        }
        .onDisappear {
            countedThisAppear = false
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                ensureProgramStateExists()
                applyDailyAdvanceIfNeeded()
            }
        }
    }

    // MARK: - Current item (stateful)

    private var programState: PracticeProgramStateEntity? {
        programStates.first
    }

    private var todayKey: String {
        Self.dayKey(for: Date())
    }

    private var isDoneToday: Bool {
        practiceCompletions.contains(where: { $0.dayKey == todayKey })
    }

    private var currentIndex: Int {
        programState?.currentIndex ?? 0
    }

    private var currentItem: PracticeItem {
        guard !items.isEmpty else { return PracticeItem(title: "Practice", body: "—") }
        let idx = max(0, min(currentIndex, items.count - 1))
        return items[idx]
    }

    // MARK: - Sections

    private var practiceCard: some View {
        let item = currentItem

        return VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.title3.weight(.semibold))

            if isExpanded {
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "Hide" : "Show")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Divider()

            doneRow
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var doneRow: some View {
        HStack {
            Text(doneStateText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                markDoneToday()
            } label: {
                Text("Done")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .disabled(isDoneToday)
        }
    }

    private var optionalHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Optional")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("If anything is still pulling at you, switch to Reflect.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    private var achievementsLink: some View {
        _ = min(108, completedTurns.count)
        let practiceCount = practiceCompletions.count

        return NavigationLink {
            ProgressScreen()
        } label: {
            TopCounterBadge(
                count: practiceCount,
                fill: practiceFill,
                textColor: .white
            )
            .overlay(Capsule().stroke(.black.opacity(0.14), lineWidth: 1))
        }
        .accessibilityLabel(Text("Practice completions: \(practiceCount)"))
    }

    private var practiceFill: Color {
        // Deep maroon / oxblood
        Color(red: 0.36, green: 0.10, blue: 0.14).opacity(0.92)
    }

    // MARK: - Done state

    private var doneStateText: String {
        isDoneToday ? "Done for today. Come back tomorrow." : "Mark as done for today."
    }

    private func markDoneToday() {
        guard !isDoneToday else { return }

        let key = todayKey
        modelContext.insert(PracticeCompletionEntity(dayKey: key))

        // Mark “pending advance” for tomorrow.
        if let state = programState {
            state.pendingAdvanceDayKey = key
            state.updatedAt = Date()
        } else {
            let state = PracticeProgramStateEntity(
                id: "singleton",
                currentIndex: 0,
                pendingAdvanceDayKey: key,
                updatedAt: Date()
            )
            modelContext.insert(state)
        }

        do { try modelContext.save() } catch { /* best-effort */ }
    }

    // MARK: - Progression (advance on next day after Done)

    private func ensureProgramStateExists() {
        guard programState == nil else { return }
        let state = PracticeProgramStateEntity()
        modelContext.insert(state)
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private func applyDailyAdvanceIfNeeded() {
        guard let state = programState else { return }

        guard let pendingFromDay = state.pendingAdvanceDayKey,
              pendingFromDay < todayKey
        else { return }

        if !items.isEmpty {
            let next = min(state.currentIndex + 1, items.count - 1) // hold last if list is shorter
            state.currentIndex = next
        }

        state.pendingAdvanceDayKey = nil
        state.updatedAt = Date()

        do { try modelContext.save() } catch { /* best-effort */ }
    }

    // MARK: - Day key helper

    private static func dayKey(for date: Date) -> String {
        let cal = Calendar.autoupdatingCurrent
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

// MARK: - Model

private struct PracticeItem {
    let title: String
    let body: String
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

