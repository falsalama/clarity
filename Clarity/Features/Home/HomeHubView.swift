import SwiftUI
import SwiftData
import UIKit

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

    @EnvironmentObject private var flow: AppFlowRouter
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

                if flow.homeTab == .practice {
                    PracticePanel(
                        introExpanded: $introExpanded,
                        todayKey: todayKey,
                        didReflectToday: didReflectToday,
                        didViewToday: didViewToday,
                        didPracticeToday: didPracticeToday,
                        dayItems: lastDays(7)
                    )
                } else {
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
        Picker("", selection: $flow.homeTab) {
            Text("Practice").tag(AppFlowRouter.HomeTab.practice)
            Text("Progress").tag(AppFlowRouter.HomeTab.progress)
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
            practiceCard
            recentCard
            focusCard
            guidanceCard
            InsightsCard()
        }
    }

    private var introductionCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Clarity")
                .font(.headline)

            Text("A Buddhist daily practice app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            DisclosureGroup(isExpanded: $introExpanded) {
                VStack(alignment: .leading, spacing: 10) {

                    Text("How it works")
                        .font(.subheadline.weight(.semibold))

                    Text("Begin each day by pressing start practice.")
                        .font(.footnote)

                    Text("One practice has three parts:")
                        .font(.footnote.weight(.semibold))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reflect - Answer one question honestly by audio or text.")
                        Text("View - A short teaching to contemplate.")
                        Text("Practice - A method to cultivate inner space.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Divider()

                    Text("Complete all three to form one unit of practice. These slowly advance over time. Return each day to build continuity.")
                        .font(.footnote.weight(.semibold))

                    Divider()

                    Text("Reflect (anytime)")
                        .font(.subheadline.weight(.semibold))

                    Text("Reflect is a private thinking instrument. It combines structured reflection with a Buddhist-informed AI assistant designed to help clarify experience rather than analyse or judge it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("You can speak or write freely. The system helps organise thoughts, reveal patterns, and support clear seeing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("On-device mode is fully private. Optional Cloud Tap processing uses redacted, anonymous text for deeper model responses.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Focus")
                        .font(.subheadline.weight(.semibold))

                    Text("Focus is an evolving collection of original meditative sounds for settling, listening, and rest.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Guidance")
                        .font(.subheadline.weight(.semibold))

                    Text("Guidance connects you with qualified Buddhist teachers and experienced practitioners for paid one-to-one sessions, practice questions, and personal instruction. These sessions create opportunities for monastics and practitioners while helping support the institutions and traditions they come from. Coming soon.")
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(alignment: .topTrailing) {
                    Image("clarityMark")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 950, height: 950)
                        .opacity(0.16)
                        .offset(x: 140, y: -260)
                        .allowsHitTesting(false)
                }
                .clipped()
        )
    }

    private var practiceCard: some View {
        let nextTitle: String = {
            if !didReflectToday { return "Start today’s practice" }
            if !didViewToday { return "Continue today’s practice" }
            if !didPracticeToday { return "Continue today’s practice" }
            return "Today complete"
        }()

        let nextSubtitle: String = {
            if !didReflectToday { return "Reflect, View, and Practice." }
            if !didViewToday { return "Next: View." }
            if !didPracticeToday { return "Next: Practice." }
            return "Reflect, View, and Practice are complete."
        }()

        let startStep: DailyFlowStep? = {
            if !didReflectToday { return .reflect }
            if !didViewToday { return .focus }
            if !didPracticeToday { return .practice }
            return nil
        }()

        return Group {
            if let startStep {
                NavigationLink {
                    DailyFlowContainerView(startAt: startStep)
                } label: {
                    PillCTA(
                        title: nextTitle,
                        subtitle: nextSubtitle,
                        systemImage: startStep == .reflect
                            ? "sun.max.fill"
                            : (startStep == .focus ? "book.closed.fill" : "leaf.fill"),
                        fill: Color(red: 0.55, green: 0.12, blue: 0.16)
                    )
                }
                .buttonStyle(.plain)
            } else {
                PillCTA(
                    title: nextTitle,
                    subtitle: nextSubtitle,
                    systemImage: "checkmark.circle.fill",
                    fill: Color(red: 0.40, green: 0.40, blue: 0.40)
                )
            }
        }
    }
    private var focusCard: some View {
        NavigationLink {
            FocusSoundsHubView()
        } label: {
            PillCTA(
                title: "Focus",
                subtitle: "Meditative sounds",
                systemImage: "waveform",
                fill: Color(red: 0.16, green: 0.36, blue: 0.78)
            )
        }
        .buttonStyle(.plain)
    }

    private var guidanceCard: some View {
        NavigationLink {
            GuidanceHubView()
        } label: {
            PillCTA(
                title: "Guidance",
                subtitle: "Book a one-to-one session with a trained Buddhist",
                systemImage: "person.2.fill",
                fill: Color(red: 0.18, green: 0.46, blue: 0.28)
            )
        }
        .buttonStyle(.plain)
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
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

private struct PillCTA: View {
    let title: String
    let subtitle: String
    var systemImage: String = "sun.max.fill"
    let fill: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.footnote)
                    .opacity(0.9)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .foregroundStyle(.white)
        .background(fill)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}

private struct InsightsCard: View {
    @EnvironmentObject private var capsuleStore: CapsuleStore
    @State private var expanded: Bool = false

    private enum Lane {
        case insight
        case leaning
        case shift
    }

    private var allItems: [CapsuleTendency] {
        capsuleStore.capsule.learnedTendencies
            .reduce(into: [CapsuleTendency]()) { acc, item in
                if !acc.contains(where: { $0.statement == item.statement }) {
                    acc.append(item)
                }
            }
    }

    private func lane(for item: CapsuleTendency) -> Lane? {
        guard
            let raw = item.sourceKindRaw,
            let kind = PatternStatsEntity.Kind(rawValue: raw)
        else {
            return nil
        }

        switch kind {
        case .antidote_lean:
            return .leaning

        case .opening_factor, .release_pattern:
            return .shift

        case .dharma_arc:
            if ["opening", "compassion", "spaciousness"].contains(item.sourceKey ?? "") {
                return .shift
            }
            return .insight

        case .afflictive_pattern, .narrative_pattern, .contraction_pattern:
            return .insight

        default:
            return nil
        }
    }

    private func sortItems(_ items: [CapsuleTendency]) -> [CapsuleTendency] {
        items.sorted {
            if $0.evidenceCount != $1.evidenceCount { return $0.evidenceCount > $1.evidenceCount }
            return $0.lastSeenAt > $1.lastSeenAt
        }
    }

    private var insightItems: [CapsuleTendency] {
        sortItems(allItems.filter { lane(for: $0) == .insight })
    }

    private var leaningItems: [CapsuleTendency] {
        sortItems(allItems.filter { lane(for: $0) == .leaning })
    }

    private var shiftItems: [CapsuleTendency] {
        sortItems(allItems.filter { lane(for: $0) == .shift })
    }

    private var visibleInsightItems: [CapsuleTendency] {
        expanded ? Array(insightItems.prefix(3)) : Array(insightItems.prefix(1))
    }

    private var visibleLeaningItems: [CapsuleTendency] {
        expanded ? Array(leaningItems.prefix(3)) : Array(leaningItems.prefix(1))
    }

    private var visibleShiftItems: [CapsuleTendency] {
        expanded ? Array(shiftItems.prefix(3)) : Array(shiftItems.prefix(1))
    }

    private var hasAnything: Bool {
        !insightItems.isEmpty || !leaningItems.isEmpty || !shiftItems.isEmpty
    }

    private var canExpand: Bool {
        insightItems.count > 1 || leaningItems.count > 1 || shiftItems.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.headline)

                Spacer()

                if canExpand {
                    Button(expanded ? "Show less" : "Show more") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expanded.toggle()
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            if !hasAnything {
                Text("Patterns will surface over time as you use Clarity.")                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    laneSection(title: "Pattern", items: visibleInsightItems)
                    laneSection(title: "Leaning", items: visibleLeaningItems)
                    laneSection(title: "Shift", items: visibleShiftItems)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private func laneSection(title: String, items: [CapsuleTendency]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("Nothing surfaced yet.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(items) { item in
                    Text(item.statement)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
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
