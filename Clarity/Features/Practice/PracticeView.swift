import SwiftUI
import SwiftData

/// PracticeView (v2.3)
/// - One small practice at a time.
/// - Deterministic: advances one step per day *only after* the user marks Done.
/// - Lock: after Done, the practice does not change until the next day.
/// - Content: remote-first (Supabase/Edge via CloudTapService) with local fallback.
/// - Mantra: optional per-step mantra shown above tab bar, fades in only after Done.
/// - Uses PracticeProgramStateEntity (singleton) to future-proof progression (modules/routes later).
struct PracticeView: View {
    @State private var bgPhase = false
    @State private var isReady = false

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeSurface: HomeSurfaceStore

    // MARK: - Data

    @Query private var completedTurns: [TurnEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    // Singleton program state row (id == "singleton")
    @Query(filter: #Predicate<PracticeProgramStateEntity> { $0.id == "singleton" })
    private var programStates: [PracticeProgramStateEntity]

    // MARK: - Remote content (DB-fed)

    private let cloudTap = CloudTapService()
    @State private var remoteItems: [PracticeItem]? = nil

    // MARK: - Practice list (local fallback seed)

    private let items: [PracticeItem] = [
        PracticeItem(
            title: "Three breaths",
            body: """
Take three natural breaths.
Nothing to fix. Nothing to achieve.
Just notice the next inhale, then the next exhale.
""",
            mantra: nil
        ),
        PracticeItem(
            title: "Soften the jaw",
            body: """
Let the jaw unclench.
Let the tongue rest.
Notice what changes when the face stops bracing.
""",
            mantra: nil
        ),
        PracticeItem(
            title: "Name the feeling",
            body: """
Silently name what is most present.
“Pressure”, “tired”, “open”, “restless”, “fine”.
No analysis. Just a clean label.
""",
            mantra: nil
        )
    ]

    private var activeItems: [PracticeItem] {
        if let remoteItems, !remoteItems.isEmpty { return remoteItems }
        return items
    }

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
        ZStack {
            Image("CloudsBG")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .opacity(0.09)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .black, location: 0.28),
                            .init(color: .black, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .scaleEffect(x: -1, y: 1) // mirror horizontally
                .offset(y: bgPhase ? 98 : 120)
                .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    practiceCard
                        .opacity(isReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.55), value: isReady)

                    optionalHint
                        .opacity(isReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.55), value: isReady)

                    Spacer(minLength: 24)
                }
                .padding()
            }
            // Prevent the “layout snap” animation of the scroll container itself.
            .transaction { $0.animation = nil }
        }
        .onAppear {
            bgPhase.toggle()
            ensureProgramStateExists()
            isReady = false
            // IMPORTANT: don't advance yet - wait until remote steps are loaded.
        }
        .animation(.easeInOut(duration: 26).repeatForever(autoreverses: true), value: bgPhase)
        .safeAreaInset(edge: .bottom) {
            mantraStrip
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Practice")
                        .font(.headline)

                    Text("One small practice each day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                achievementsLink
            }
        }
        .task {
            await loadRemotePracticeStepsIfNeeded()
            applyDailyAdvanceIfNeeded()
            withAnimation(.easeOut(duration: 0.55)) {
                isReady = true
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }

            isReady = false
            ensureProgramStateExists()

            Task {
                await loadRemotePracticeStepsIfNeeded()
                await MainActor.run {
                    applyDailyAdvanceIfNeeded()
                    withAnimation(.easeOut(duration: 0.55)) {
                        isReady = true
                    }
                }
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
        let list = activeItems
        guard !list.isEmpty else { return PracticeItem(title: "Practice", body: "—", mantra: nil) }
        let idx = max(0, min(currentIndex, list.count - 1))
        return list[idx]
    }

    // MARK: - Mantra strip

    private var currentMantra: String? {
        let raw = currentItem.mantra?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }

    private var mantraStrip: some View {
        Group {
            if let m = currentMantra {
                Text(m)
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .opacity(isDoneToday ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: isDoneToday)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Sections

    private var practiceCard: some View {
        let item = currentItem

        return VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.title3.weight(.semibold))

            Text(item.body)
                .font(.body)
                .foregroundStyle(.primary)

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
        .padding(.horizontal, 6)
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
        modelContext.insert(PracticeProgramStateEntity())
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private func applyDailyAdvanceIfNeeded() {
        guard let state = programState else { return }

        guard let pendingFromDay = state.pendingAdvanceDayKey,
              pendingFromDay < todayKey
        else { return }

        let list = activeItems
        if !list.isEmpty {
            let next = min(state.currentIndex + 1, list.count - 1)
            state.currentIndex = next
        }

        state.pendingAdvanceDayKey = nil
        state.updatedAt = Date()

        do { try modelContext.save() } catch { /* best-effort */ }
    }

    // MARK: - Remote load

    @MainActor
    private func loadRemotePracticeStepsIfNeeded() async {
        if let remoteItems, !remoteItems.isEmpty { return }

        do {
            let resp = try await cloudTap.practiceSteps(programme: "core")

            let mapped: [PracticeItem] = resp.steps
                .sorted(by: { $0.stepIndex < $1.stepIndex })
                .map { step in
                    PracticeItem(
                        title: step.title,
                        body: step.body,
                        mantra: step.mantra
                    )
                }

            if !mapped.isEmpty {
                remoteItems = mapped

                if let state = programState, state.currentIndex > max(0, mapped.count - 1) {
                    state.currentIndex = max(0, mapped.count - 1)
                    state.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        } catch {
            // Silent fallback to local seed items.
        }
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
    let mantra: String?
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
