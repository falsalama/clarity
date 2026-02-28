import SwiftUI
import SwiftData

// MARK: - Day snapshot types (file-scope, accessible to subviews)

fileprivate enum DayStatus { case none, partial, full }

fileprivate struct DayItem: Identifiable {
    let id: String          // dayKey
    let dayKey: String
    let label: String       // Today / Yesterday / "Tue 26"
    let status: DayStatus
}

/// Home hub content only (no NavigationStack, no toolbar).
/// Top segmented header: Practice | Progress (Strava-like, but non-gamified).
struct HomeHubView: View {
    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    private enum HomeTab: String { case practice, progress }
    @State private var tab: HomeTab = .practice

    @State private var introExpanded: Bool = false

    init() {
        _reflectCompletions = Query(sort: [SortDescriptor(\ReflectCompletionEntity.completedAt, order: .reverse)])
        _focusCompletions = Query(sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)])
        _practiceCompletions = Query(sort: [SortDescriptor(\PracticeCompletionEntity.completedAt, order: .reverse)])
    }

    private var todayKey: String { Date().dayKey() }

    private var didReflectToday: Bool { reflectCompletions.first(where: { $0.dayKey == todayKey }) != nil }
    private var didViewToday: Bool { focusCompletions.first(where: { $0.dayKey == todayKey }) != nil }
    private var didPracticeToday: Bool { practiceCompletions.first(where: { $0.dayKey == todayKey }) != nil }

    // A “practice unit” = all three completed on the same dayKey
    private var practiceUnitCount: Int {
        let r = Set(reflectCompletions.map { $0.dayKey })
        let v = Set(focusCompletions.map { $0.dayKey })
        let p = Set(practiceCompletions.map { $0.dayKey })
        return r.intersection(v).intersection(p).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerSegment

                if tab == .practice {
                    PracticePanel(
                        introExpanded: $introExpanded,
                        todayKey: todayKey,
                        didReflectToday: didReflectToday,
                        didViewToday: didViewToday,
                        didPracticeToday: didPracticeToday,
                        dayItems: lastDays(7)
                    )
                } else {
                    // Progress tab: show ProgressScreen directly (no extra header card)
                    ProgressScreen()
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Header

    private var headerSegment: some View {
        Picker("", selection: $tab) {
            Text("Practice").tag(HomeTab.practice)
            Text("Progress").tag(HomeTab.progress)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Home sections")
    }

    // MARK: - Last days snapshot

    private func lastDays(_ n: Int) -> [DayItem] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let reflectSet = Set(reflectCompletions.map { $0.dayKey })
        let viewSet = Set(focusCompletions.map { $0.dayKey })
        let practiceSet = Set(practiceCompletions.map { $0.dayKey })

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_GB")
        df.setLocalizedDateFormatFromTemplate("EEE d")

        return (0..<n).compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = d.dayKey()

            let doneR = reflectSet.contains(key)
            let doneV = viewSet.contains(key)
            let doneP = practiceSet.contains(key)

            let count = (doneR ? 1 : 0) + (doneV ? 1 : 0) + (doneP ? 1 : 0)
            let status: DayStatus = (count == 0) ? .none : (count == 3 ? .full : .partial)

            let label: String
            if offset == 0 { label = "Today" }
            else if offset == 1 { label = "Yesterday" }
            else { label = df.string(from: d) }

            return DayItem(id: key, dayKey: key, label: label, status: status)
        }
    }
}

// MARK: - Panels

private struct PracticePanel: View {
    @Binding var introExpanded: Bool

    let todayKey: String
    let didReflectToday: Bool
    let didViewToday: Bool
    let didPracticeToday: Bool
    let dayItems: [DayItem]

    var body: some View {
        VStack(spacing: 16) {
            introductionCard
            todayCard
            recentCard
        }
    }

    private var introductionCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Clarity")
                .font(.headline)

            // IMPORTANT:
            // Paste your updated “Clarity about text” here as normal strings.
            // Do NOT paste code, only text in quotes.
            Text("A Buddhist daily practice app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            DisclosureGroup(isExpanded: $introExpanded) {
                VStack(alignment: .leading, spacing: 10) {

                    // Replace this block with your updated copy (strings only).
                    Text("How it works")
                        .font(.subheadline.weight(.semibold))
                    
                   Text("Begin each day by pressing start practice.")
                      Text("One Practice has three sections:")
                        .font(.footnote.weight(.semibold))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reflect - Answer one question honestly by audio or text.")
                        Text("View - A short teaching to contemplate.")
                        Text("Practice - A method to cultivate inner space.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Divider()

                    Text("Complete all three to form one unit of practice. These will slowely advance. Return each day to build momemtum.")
                        .font(.footnote.weight(.semibold))

                    Divider()

                    Text("Reflect (anytime)")
                        .font(.subheadline.weight(.semibold))

                    Text("Reflect can also be used independently to think clearly, offload thoughts, or explore confusion in private.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("On-device mode is fully private. Optional Cloud Tap processing (premium) uses redacted, anonymous text for deeper model responses.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Capsule")
                        .font(.subheadline.weight(.semibold))

                    Text("Capsule is your adaptive learning layer. If enabled, it gradually tailors questions and teachings to your patterns over time. Capsule stores structure, not secrets.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("This app is not therapy and does not replace a teacher. It is a structured instrument for contemplative training.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
            } label: {
                Text(introExpanded ? "Hide details" : "Learn more")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var todayCard: some View {
        let nextTitle: String = {
            if !didReflectToday { return "Start today’s practice" }
            if !didViewToday { return "Continue today’s practice" }
            if !didPracticeToday { return "Continue today’s practice" }
            return "Today complete"
        }()

        let nextSubtitle: String = {
            if !didReflectToday { return "Begin with Reflect, then View, then Practice." }
            if !didViewToday { return "Next: View." }
            if !didPracticeToday { return "Next: Practice." }
            return "Reflect, View, and Practice are complete."
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Text(todayKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Group {
                if !didReflectToday {
                    NavigationLink { CaptureView(autoPopOnDone: true) } label: {
                        PrimaryCTA(title: nextTitle, subtitle: nextSubtitle)
                    }
                } else if !didViewToday {
                    NavigationLink { FocusView() } label: {
                        PrimaryCTA(title: nextTitle, subtitle: nextSubtitle)
                    }
                } else if !didPracticeToday {
                    NavigationLink { PracticeView() } label: {
                        PrimaryCTA(title: nextTitle, subtitle: nextSubtitle)
                    }
                } else {
                    PrimaryCTA(title: nextTitle, subtitle: nextSubtitle, isComplete: true)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
    private struct PrimaryCTA: View {
        let title: String
        let subtitle: String
        var isComplete: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "chevron.right")
                        .foregroundStyle(.secondary)
                }

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
        }
    }
    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dayItems) { item in
                        NavigationLink {
                            DayDetailView(dayKey: item.dayKey, label: item.label)
                        } label: {
                            DayChip(label: item.label, status: item.status)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Text("No streaks. This is a simple record of continuity.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

private struct ProgressPanel: View {
    let practiceUnitCount: Int

    var body: some View {
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 10) {
                Text("Progress")
                    .font(.headline)

                Text("A practice unit is formed when Reflect, View, and Practice are all completed on the same day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Practice units")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(practiceUnitCount)")
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 6)

                Text("")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

            // Existing full Progress UI (bloom, portrait, unlocking etc)
            ProgressScreen()
        }
    }
}
// MARK: - Subviews

private struct TodayRow: View {
    let title: String
    let subtitle: String
    let isDone: Bool
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isDone ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .contentShape(Rectangle())
    }
}

private struct DayChip: View {
    let label: String
    let status: DayStatus

    var body: some View {
        HStack(spacing: 8) {
            statusDot
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }

    private var statusDot: some View {
        Group {
            switch status {
            case .none:
                Circle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1.5)
            case .partial:
                Circle().fill(Color.secondary.opacity(0.55))
            case .full:
                Circle().fill(Color.primary.opacity(0.85))
            }
        }
        .frame(width: 10, height: 10)
        .accessibilityHidden(true)
    }
}
