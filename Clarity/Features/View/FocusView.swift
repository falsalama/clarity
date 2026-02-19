import SwiftUI
import SwiftData

/// FocusView (v2.3)
/// - One short teaching at a time.
/// - Deterministic: advances one step per day *only after* the user marks Done.
/// - Lock: after Done, the teaching does not change until the next day.
/// - Content: remote-first (Supabase/Edge via CloudTapService) with local fallback.
/// - Mantra: optional per-step mantra shown above tab bar, fades in only after Done.
/// - Uses FocusProgramStateEntity (singleton) to future-proof progression (modules/routes later).
struct FocusView: View {
    @State private var bgPhase = false
    @State private var isReady = false

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeSurface: HomeSurfaceStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Data

    @Query private var completedTurns: [TurnEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]

    // Singleton program state row (id == "singleton")
    @Query(filter: #Predicate<FocusProgramStateEntity> { $0.id == "singleton" })
    private var programStates: [FocusProgramStateEntity]

    // MARK: - Remote content (DB-fed)

    private let cloudTap = CloudTapService()
    @State private var remoteTeachings: [Teaching]? = nil

    // MARK: - Teaching list (local fallback seed)

    private let teachings: [Teaching] = [
        Teaching(
            title: "Training attention",
            body: """
Notice where the mind goes when it is not being directed.
There is no need to stop it or improve it.
Just see how it moves on its own.
""",
            prompt: "What do you notice about how your attention moves?",
            mantra: nil
        ),
        Teaching(
            title: "Working with change",
            body: """
Everything that appears also changes.
This includes thoughts, moods, and situations.
Nothing needs to be held in place.
""",
            prompt: "Where do you notice change happening right now?",
            mantra: nil
        ),
        Teaching(
            title: "Softening effort",
            body: """
Often we add effort on top of experience.
See what happens if effort relaxes slightly.
Nothing is lost.
""",
            prompt: "What eases when effort softens?",
            mantra: nil
        )
    ]

    private var activeTeachings: [Teaching] {
        if let remoteTeachings, !remoteTeachings.isEmpty { return remoteTeachings }
        return teachings
    }

    // MARK: - Init

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )

        _focusCompletions = Query(
            sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)]
        )
    }

    // MARK: - View

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("CloudsBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .scaleEffect(bgPhase ? 1.04 : 0.98, anchor: .bottom)
                    .offset(x: bgPhase ? 0 : 10, y: bgPhase ? 94 : 44)
                    .opacity(0.20)
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.0), .white.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .animation(.easeInOut(duration: 26).repeatForever(autoreverses: true), value: bgPhase)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    teachingCard
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
        .safeAreaInset(edge: .bottom) {
            mantraStrip
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("View")
                        .font(.headline)

                    Text("One small teaching each day.")
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
        .onAppear {
            bgPhase = !reduceMotion
            isReady = false
            ensureProgramStateExists()
            applyDailyAdvanceIfNeeded()
        }
        .task {
            await loadRemoteFocusStepsIfNeeded()
            withAnimation(.easeOut(duration: 0.55)) {
                isReady = true
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }

            isReady = false
            ensureProgramStateExists()
            applyDailyAdvanceIfNeeded()

            Task {
                await loadRemoteFocusStepsIfNeeded()
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.55)) {
                        isReady = true
                    }
                }
            }
        }
    }

    // MARK: - Teaching selection (stateful)

    private var programState: FocusProgramStateEntity? {
        programStates.first
    }

    private var todayKey: String {
        Self.dayKey(for: Date())
    }

    private var isDoneToday: Bool {
        focusCompletions.contains(where: { $0.dayKey == todayKey })
    }

    private var currentIndex: Int {
        programState?.currentIndex ?? 0
    }

    private var currentTeaching: Teaching {
        let list = activeTeachings
        guard !list.isEmpty else { return Teaching(title: "View", body: "—", prompt: "", mantra: nil) }
        let idx = max(0, min(currentIndex, list.count - 1))
        return list[idx]
    }

    // MARK: - Mantra strip

    private var currentMantra: String? {
        let raw = currentTeaching.mantra?.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var teachingCard: some View {
        let teaching = currentTeaching

        return VStack(alignment: .leading, spacing: 12) {
            Text(teaching.title)
                .font(.title3.weight(.semibold))

            Text(teaching.body)
                .font(.body)

            let prompt = teaching.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            if !prompt.isEmpty {
                Divider()

                Text(prompt)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

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
        let focusCount = focusCompletions.count

        return NavigationLink {
            ProgressScreen()
        } label: {
            TopCounterBadge(
                count: focusCount,
                fill: focusFill,
                textColor: .black
            )
            .overlay(Capsule().stroke(.black.opacity(0.10), lineWidth: 1))
        }
        .accessibilityLabel(Text("View completions: \(focusCount)"))
    }

    private var focusFill: Color {
        Color(red: 0.92, green: 0.80, blue: 0.34).opacity(0.92)
    }

    // MARK: - Done state text

    private var doneStateText: String {
        isDoneToday ? "Done for today. Come back tomorrow." : "Mark as done for today."
    }

    private func markDoneToday() {
        guard !isDoneToday else { return }

        let key = todayKey
        modelContext.insert(FocusCompletionEntity(dayKey: key))

        if let state = programState {
            state.pendingAdvanceDayKey = key
            state.updatedAt = Date()
        } else {
            let state = FocusProgramStateEntity(
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
        modelContext.insert(FocusProgramStateEntity())
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private func applyDailyAdvanceIfNeeded() {
        guard let state = programState else { return }

        guard let pendingFromDay = state.pendingAdvanceDayKey,
              pendingFromDay < todayKey
        else { return }

        let list = activeTeachings
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
    private func loadRemoteFocusStepsIfNeeded() async {
        if let remoteTeachings, !remoteTeachings.isEmpty { return }

        do {
            let resp = try await cloudTap.focusSteps(programme: "core")

            let mapped: [Teaching] = resp.steps
                .sorted(by: { $0.stepIndex < $1.stepIndex })
                .map { step in
                    let (body, prompt) = Self.splitBodyAndPrompt(step.body)
                    return Teaching(
                        title: step.title,
                        body: body,
                        prompt: prompt,
                        mantra: step.mantra
                    )
                }

            if !mapped.isEmpty {
                remoteTeachings = mapped

                if let state = programState, state.currentIndex > max(0, mapped.count - 1) {
                    state.currentIndex = max(0, mapped.count - 1)
                    state.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        } catch {
            // Silent fallback to local seed teachings.
        }
    }

    private static func splitBodyAndPrompt(_ body: String) -> (String, String) {
        let marker = "\n\nPrompt:"
        if let r = body.range(of: marker) {
            let main = String(body[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let prompt = String(body[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (main, prompt.isEmpty ? "" : prompt)
        }
        return (body.trimmingCharacters(in: .whitespacesAndNewlines), "")
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

private struct Teaching {
    let title: String
    let body: String
    let prompt: String
    let mantra: String?
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

