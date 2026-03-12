import SwiftUI
import SwiftData
import UIKit

// MARK: - Day snapshot types

fileprivate enum DayStatus { case none, partial, full }

fileprivate struct DayItem: Identifiable {
    let id: String
    let dayKey: String
    let label: String
    let status: DayStatus
}

/// Home hub content only (no NavigationStack, no toolbar).
/// Top segmented header: Practice | Progress
struct HomeHubView: View {
    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    @EnvironmentObject private var flow: AppFlowRouter

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

    private var todayKey: String { Date().dayKey() }

    private var didReflectToday: Bool {
        reflectCompletions.first(where: { $0.dayKey == todayKey }) != nil
    }

    private var didViewToday: Bool {
        focusCompletions.first(where: { $0.dayKey == todayKey }) != nil
    }

    private var didPracticeToday: Bool {
        practiceCompletions.first(where: { $0.dayKey == todayKey }) != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerSegment

                if flow.homeTab == .practice {
                    PracticePanel(
                        todayKey: todayKey,
                        didReflectToday: didReflectToday,
                        didViewToday: didViewToday,
                        didPracticeToday: didPracticeToday
                    )
                } else {
                    ProgressPanel(dayItems: lastDays(7))
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
            if offset == 0 {
                label = "Today"
            } else if offset == 1 {
                label = "Yesterday"
            } else {
                label = df.string(from: d)
            }

            return DayItem(id: key, dayKey: key, label: label, status: status)
        }
    }
}

// MARK: - Practice tab

private struct PracticePanel: View {
    let todayKey: String
    let didReflectToday: Bool
    let didViewToday: Bool
    let didPracticeToday: Bool

    var body: some View {
        VStack(spacing: 0) {
            practiceCard
        }
    }

    private var practiceCard: some View {
        let nextTitle: String = {
            if !didReflectToday { return "Start daily practice" }
            if !didViewToday { return "Continue daily practice" }
            if !didPracticeToday { return "Continue daily practice" }
            return "Daily practice complete"
        }()

        let nextSubtitle: String = {
            if !didReflectToday { return "Reflect, View, and Practice." }
            if !didViewToday { return "Next: View." }
            if !didPracticeToday { return "Next: Practice." }
            return "All three parts are complete."
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
                    HomePracticeCard(
                        title: nextTitle,
                        subtitle: nextSubtitle,
                        systemImage: startStep == .reflect
                            ? "sun.max.fill"
                            : (startStep == .focus ? "book.closed.fill" : "leaf.fill"),
                        fill: Color(red: 0.55, green: 0.12, blue: 0.16),
                        imageAssetName: HomePracticeCardStyle.imageAssetName,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            } else {
                HomePracticeCard(
                    title: nextTitle,
                    subtitle: nextSubtitle,
                    systemImage: "checkmark.circle.fill",
                    fill: Color(red: 0.40, green: 0.40, blue: 0.40),
                    imageAssetName: HomePracticeCardStyle.imageAssetName,
                    showsChevron: false
                )
            }
        }
    }
}

// MARK: - Bigger home practice card

private struct HomePracticeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let fill: Color
    let imageAssetName: String
    let showsChevron: Bool

    var body: some View {
        VStack(spacing: 0) {
            heroImage
                .frame(height: HomePracticeCardStyle.imageHeight)

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.subheadline)
                        .opacity(0.92)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: showsChevron ? "chevron.right" : "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.9)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
        }
        .foregroundStyle(.white)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var heroImage: some View {
        if UIImage(named: imageAssetName) != nil {
            Image(imageAssetName)
                .resizable()
                .aspectRatio(contentMode: HomePracticeCardStyle.imageContentMode)
                .scaleEffect(HomePracticeCardStyle.imageScale, anchor: .center)
                .frame(maxWidth: .infinity)
                .clipped()
                .offset(y: HomePracticeCardStyle.imageVerticalOffset)
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        fill.opacity(0.95),
                        fill.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image("clarityMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .opacity(0.12)
                    .offset(x: 56, y: -14)
            }
        }
    }
}

private enum HomePracticeCardStyle {
    static let imageAssetName = "kailash"
    static let imageHeight: CGFloat = 248
    static let imageScale: CGFloat = 1.0
    static let imageVerticalOffset: CGFloat = 0
    static let imageContentMode: ContentMode = .fill
}

// MARK: - Progress tab wrapper

private struct ProgressPanel: View {
    let dayItems: [DayItem]

    var body: some View {
        VStack(spacing: 12) {
            ProgressScreen()
            InsightsCard()
            compactRecentCard
        }
    }

    private var compactRecentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(dayItems.prefix(5))) { item in
                        NavigationLink {
                            DayDetailView(dayKey: item.dayKey, label: item.label)
                        } label: {
                            CompactDayChip(label: item.label, status: item.status)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Insights

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
                Text("Patterns will surface over time as you use Clarity.")
                    .font(.subheadline.weight(.semibold))
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

// MARK: - Day chips

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

private struct CompactDayChip: View {
    let label: String
    let status: DayStatus

    var body: some View {
        HStack(spacing: 6) {
            statusDot
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color(.systemBackground)))
    }

    private var statusDot: some View {
        Group {
            switch status {
            case .none:
                Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.1)
            case .partial:
                Circle().fill(Color.secondary.opacity(0.50))
            case .full:
                Circle().fill(Color.primary.opacity(0.78))
            }
        }
        .frame(width: 7, height: 7)
        .accessibilityHidden(true)
    }
}
