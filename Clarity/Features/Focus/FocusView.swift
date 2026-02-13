// FocusView.swift

import SwiftUI
import SwiftData

/// FocusView (v1)
/// - One short teaching at a time.
/// - Adds a light “Done” action (one per day) to count Focus completions.
struct FocusView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Data

    @Query private var completedTurns: [TurnEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var todayFocusCompletions: [FocusCompletionEntity]

    private let teachings: [Teaching] = [
        Teaching(
            title: "Training attention",
            body: """
Notice where the mind goes when it is not being directed.
There is no need to stop it or improve it.
Just see how it moves on its own.
""",
            prompt: "What do you notice about how your attention moves?"
        ),
        Teaching(
            title: "Working with change",
            body: """
Everything that appears also changes.
This includes thoughts, moods, and situations.
Nothing needs to be held in place.
""",
            prompt: "Where do you notice change happening right now?"
        ),
        Teaching(
            title: "Softening effort",
            body: """
Often we add effort on top of experience.
See what happens if effort relaxes slightly.
Nothing is lost.
""",
            prompt: "What eases when effort softens?"
        )
    ]

    @State private var teaching: Teaching

    // MARK: - Init

    init() {
        _teaching = State(initialValue: teachings.randomElement()!)

        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )

        _focusCompletions = Query(
            sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)]
        )

        let key = FocusView.dayKey(for: Date())
        _todayFocusCompletions = Query(
            filter: #Predicate<FocusCompletionEntity> { item in
                item.dayKey == key
            }
        )
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                teachingCard

                optionalHint

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                achievementsLink
            }
        }
    }

    // MARK: - Sections

    private var teachingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(teaching.title)
                .font(.title3.weight(.semibold))

            Text(teaching.body)
                .font(.body)

            Divider()

            Text(teaching.prompt)
                .font(.callout)
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
                Text(doneButtonTitle)
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

            Text("If this brings something up, you can reflect on it.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
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
        .accessibilityLabel(Text("Focus completions: \(focusCount)"))
    }

    private var focusFill: Color {
        // Muted gold
        Color(red: 0.92, green: 0.80, blue: 0.34).opacity(0.92)
    }

    // MARK: - Done state

    private var isDoneToday: Bool {
        !todayFocusCompletions.isEmpty
    }

    private var doneButtonTitle: String {
        isDoneToday ? "Done" : "Done"
    }

    private var doneStateText: String {
        isDoneToday ? "Marked done for today." : "Mark as done for today."
    }

    private func markDoneToday() {
        guard !isDoneToday else { return }

        let key = Self.dayKey(for: Date())
        modelContext.insert(FocusCompletionEntity(dayKey: key))
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

private struct Teaching {
    let title: String
    let body: String
    let prompt: String
}
