// PracticeView.swift

import SwiftUI
import SwiftData

/// PracticeView (v1)
/// - A tiny instruction surface.
/// - Adds a light “Done” action (one per day) to count Practice completions.
struct PracticeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Data

    @Query private var completedTurns: [TurnEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]
    @Query private var todayPracticeCompletions: [PracticeCompletionEntity]

    private let title = "Practice"
    private let instruction = """
Take three natural breaths.
Nothing to fix. Nothing to achieve.
Just notice the next inhale, then the next exhale.
"""

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

        let key = PracticeView.dayKey(for: Date())
        _todayPracticeCompletions = Query(
            filter: #Predicate<PracticeCompletionEntity> { item in
                item.dayKey == key
            }
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                achievementsLink
            }
        }
    }

    // MARK: - Sections

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A tiny practice")
                .font(.headline)

            if isExpanded {
                Text(instruction)
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

    private var isDoneToday: Bool {
        !todayPracticeCompletions.isEmpty
    }

    private var doneStateText: String {
        isDoneToday ? "Marked done for today." : "Mark as done for today."
    }

    private func markDoneToday() {
        guard !isDoneToday else { return }

        let key = Self.dayKey(for: Date())
        modelContext.insert(PracticeCompletionEntity(dayKey: key))
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
