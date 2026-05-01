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
    @StateObject private var calendarStore = CalendarStore()

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

    private var todayCalendarBadgeText: String? {
        guard calendarStore.today.isEmpty == false else { return nil }
        return Self.ordinalDayString(for: Date())
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if flow.homeTab == .practice {
                HomeHubBackground()
            }

            if flow.homeTab == .practice {
                VStack(spacing: 14) {
                    headerSegment

                    PracticePanel(
                        todayKey: todayKey,
                        didReflectToday: didReflectToday,
                        didViewToday: didViewToday,
                        didPracticeToday: didPracticeToday,
                        beginAnimationSeed: flow.homeHubEntrySeed,
                        todayCalendarBadgeText: todayCalendarBadgeText
                    )

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 22)
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        headerSegment
                        ProgressPanel(dayItems: lastDays(7))
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
                }
            }
        }
        .task {
            if calendarStore.today.isEmpty, calendarStore.upcoming.isEmpty {
                await calendarStore.refresh()
            }
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

    private static func ordinalDayString(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let suffix: String

        switch day {
        case 11, 12, 13:
            suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }

        return "\(day)\(suffix)"
    }
}

// MARK: - Background

private struct HomeHubBackground: View {
    @State private var animate = false
    @State private var revealPoint: CGPoint? = nil
    @State private var revealAmount: CGFloat = 0

    private let revealSize: CGFloat = 360

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundImage(named: "homehubbg", in: proxy)

                if let revealPoint {
                    backgroundImage(named: "homehubbgcolour", in: proxy)
                        .opacity(revealAmount)
                        .mask {
                            ZStack {
                                Color.clear

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            stops: [
                                                .init(color: .white.opacity(1.0), location: 0.00),
                                                .init(color: .white.opacity(0.96), location: 0.18),
                                                .init(color: .white.opacity(0.78), location: 0.36),
                                                .init(color: .white.opacity(0.40), location: 0.62),
                                                .init(color: .white.opacity(0.12), location: 0.82),
                                                .init(color: .clear, location: 1.00)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: revealSize * (0.48 + (revealAmount * 0.12))
                                        )
                                    )
                                    .frame(
                                        width: revealSize * (0.96 + revealAmount * 0.08),
                                        height: revealSize * (0.96 + revealAmount * 0.08)
                                    )
                                    .position(revealPoint)
                                    .blur(radius: 26)
                            }
                            .compositingGroup()
                        }
                        .overlay {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.10),
                                            Color.cyan.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: revealSize * 0.34
                                    )
                                )
                                .frame(width: revealSize * 0.72, height: revealSize * 0.72)
                                .position(revealPoint)
                                .opacity(revealAmount * 0.55)
                                .blur(radius: 20)
                        }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        revealPoint = value.location
                        withAnimation(.easeOut(duration: 0.14)) {
                            revealAmount = 1
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.85)) {
                            revealAmount = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
                            if revealAmount == 0 {
                                revealPoint = nil
                            }
                        }
                    }
            )
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func backgroundImage(named name: String, in proxy: GeometryProxy) -> some View {
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(1.04)
                .offset(x: 0, y: 82)
                .overlay(
                    name == "homehubbg"
                    ? LinearGradient(
                        colors: [
                            Color(.systemBackground).opacity(0.18),
                            Color(.systemBackground).opacity(0.04),
                            Color(.systemBackground).opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(name == "homehubbg" ? 0.30 : 1.0)
                .ignoresSafeArea()
        }
    }
}
// MARK: - Liquid touch orb
private struct LiquidTouchOrb: View {
    let point: CGPoint

    private let size: CGFloat = 144

    @State private var currentPoint: CGPoint = .zero
    @State private var lastPoint: CGPoint = .zero
    @State private var hasInitialised = false

    private var trailDX: CGFloat { (lastPoint.x - currentPoint.x) * 0.22 }
    private var trailDY: CGFloat { (lastPoint.y - currentPoint.y) * 0.22 }

    var body: some View {
        ZStack {
            wateryTrail
            outerGlowHaze
            mainOrb
        }
        .frame(width: size, height: size)
        .position(currentPoint == .zero ? point : currentPoint)
        .onAppear {
            currentPoint = point
            lastPoint = point
            hasInitialised = true
        }
        .onChange(of: point) { _, newValue in
            guard hasInitialised else {
                currentPoint = newValue
                lastPoint = newValue
                hasInitialised = true
                return
            }

            lastPoint = currentPoint

            withAnimation(.easeOut(duration: 0.28)) {
                currentPoint = newValue
            }

            withAnimation(.easeOut(duration: 0.52)) {
                lastPoint = newValue
            }
        }
    }

    private var wateryTrail: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .opacity(0.10)
            .frame(width: size * 0.98, height: size * 0.98)
            .blur(radius: 14)
            .scaleEffect(1.02)
            .offset(x: trailDX, y: trailDY)
    }

    private var outerGlowHaze: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.62
                )
            )
            .frame(width: size * 1.02, height: size * 1.02)
            .blur(radius: 10)
    }

    private var mainOrb: some View {
        ZStack {
            orbMaterial
            topHighlight
            bottomHighlight
            specularHighlight
            innerRim
            softOuterRim
            shadowRim
        }
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private var orbMaterial: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .opacity(0.26)
    }

    private var topHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        Color.white.opacity(0.16),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: size * 0.52
                )
            )
            .blur(radius: 2.2)
    }

    private var bottomHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: size * 0.42
                )
            )
            .blur(radius: 6)
    }

    private var specularHighlight: some View {
        Ellipse()
            .fill(Color.white.opacity(0.28))
            .frame(width: size * 0.28, height: size * 0.11)
            .blur(radius: 1.4)
            .offset(x: -18, y: -28)
    }

    private var innerRim: some View {
        Circle()
            .stroke(Color.white.opacity(0.34), lineWidth: 1.0)
    }

    private var softOuterRim: some View {
        Circle()
            .stroke(Color.white.opacity(0.12), lineWidth: 10)
            .blur(radius: 10)
            .padding(2)
    }

    private var shadowRim: some View {
        Circle()
            .stroke(Color.black.opacity(0.05), lineWidth: 1.0)
            .blur(radius: 1.0)
            .offset(y: 1)
    }
}
// MARK: - Practice tab

private struct PracticePanel: View {
    let todayKey: String
    let didReflectToday: Bool
    let didViewToday: Bool
    let didPracticeToday: Bool
    let beginAnimationSeed: Int
    let todayCalendarBadgeText: String?

    @State private var beginTouchPoint: CGPoint? = nil

    private let compassionFill = Color(red: 0.62, green: 0.28, blue: 0.34)

    private var beginIntroHasPlayed: Bool {
        beginAnimationSeed > 0
    }

    private var buttonTitle: String {
        if !didReflectToday { return "Begin" }
        if !didViewToday { return "Continue" }
        if !didPracticeToday { return "Continue" }
        return "Complete"
    }

    private var startStep: DailyFlowStep? {
        if !didReflectToday { return .reflect }
        if !didViewToday { return .focus }
        if !didPracticeToday { return .practice }
        return nil
    }

    // Begin - fixed, independent position
    private let beginCenterY: CGFloat = 288
    private let beginHitWidth: CGFloat = 300
    private let beginHitHeight: CGFloat = 150

    // Dorje - fixed, independent position
    private let dorjeSize: CGFloat = 115
    private let dorjeHitSize: CGFloat = 115
    private let dorjeTrailingInset: CGFloat = 75
    private let dorjeBottomInset: CGFloat = 174
    private let dorjeOpacity: Double = 0.9

    // Lotus - fixed, independent position
    private let lotusSize: CGFloat = 118
    private let lotusHitSize: CGFloat = 118
    private let lotusLeadingInset: CGFloat = 94
    private let lotusBottomInset: CGFloat = 25
    private let lotusOpacity: Double = 0.9

    // Today calendar link
    private let todayLinkLeadingInset: CGFloat = 56
    private let todayLinkCenterY: CGFloat = 176

    var body: some View {
        GeometryReader { geo in
            ZStack {
                beginBlock(
                    at: CGPoint(
                        x: geo.size.width * 0.5,
                        y: beginCenterY
                    )
                )

                lotusBlock(
                    at: CGPoint(
                        x: lotusLeadingInset,
                        y: geo.size.height - lotusBottomInset
                    )
                )

                if let todayCalendarBadgeText {
                    todayCalendarBlock(
                        text: todayCalendarBadgeText,
                        at: CGPoint(
                            x: todayLinkLeadingInset,
                            y: todayLinkCenterY
                        )
                    )
                }

                dorjeBlock(
                    at: CGPoint(
                        x: geo.size.width - dorjeTrailingInset,
                        y: geo.size.height - dorjeBottomInset
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    @ViewBuilder
    private func beginBlock(at point: CGPoint) -> some View {
        ZStack {
            if let startStep {
                NavigationLink {
                    DailyFlowContainerView(startAt: startStep)
                } label: {
                    ZStack {
                        Color.clear
                        BeginPracticeButtonView(
                            text: buttonTitle,
                            isEnabled: true,
                            animationSeed: beginAnimationSeed,
                            introHasPlayed: beginIntroHasPlayed,
                            touchPoint: beginTouchPoint
                        )
                    }
                    .frame(width: beginHitWidth, height: beginHitHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    Color.clear
                    BeginPracticeButtonView(
                        text: buttonTitle,
                        isEnabled: true,
                        animationSeed: beginAnimationSeed,
                        introHasPlayed: beginIntroHasPlayed,
                        touchPoint: beginTouchPoint
                    )
                }
                .frame(width: beginHitWidth, height: beginHitHeight)
                .contentShape(Rectangle())
            }

            if let beginTouchPoint {
                LiquidTouchOrb(point: beginTouchPoint)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: beginHitWidth, height: beginHitHeight)
        .coordinateSpace(name: "beginArea")
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("beginArea"))
                .onChanged { value in
                    beginTouchPoint = value.location
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.18)) {
                        beginTouchPoint = nil
                    }
                }
        )
        .position(point)
    }

    @ViewBuilder
    private func lotusBlock(at point: CGPoint) -> some View {
        NavigationLink {
            CompassionView()
        } label: {
            ZStack {
                Color.clear
                    .frame(width: lotusHitSize, height: lotusHitSize)

                Image("lotus")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: lotusSize, height: lotusSize)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LotusPressStyle())
        .position(point)
    }

    @ViewBuilder
    private func dorjeBlock(at point: CGPoint) -> some View {
        NavigationLink {
            WisdomView()
        } label: {
            ZStack {
                Color.clear
                    .frame(width: dorjeHitSize, height: dorjeHitSize)

                Image("dorje2")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: dorjeSize, height: dorjeSize)
                    .opacity(dorjeOpacity)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(point)
    }

    @ViewBuilder
    private func todayCalendarBlock(text: String, at point: CGPoint) -> some View {
        NavigationLink {
            CalendarView()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Color.primary.opacity(0.62))

                Text("Today")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.38))
            }
            .frame(width: 64, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(point)
    }
}
// MARK: - Begin button

private struct BeginPracticeButtonView: View {
    let text: String
    let isEnabled: Bool
    let animationSeed: Int
    let introHasPlayed: Bool
    let touchPoint: CGPoint?

    @State private var fadeIn = false
    @State private var revealProgress: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    private let writeStartDelay: Double = 0.18
    private let writeDuration: Double = 1.85
    private let beginInk: Double = 0.88
    private let beginFontSize: CGFloat = 42
    private let featherWidth: CGFloat = 52
    private let penDotSize: CGFloat = 9

    private let areaWidth: CGFloat = 300
    private let areaHeight: CGFloat = 150

    private var revealWidth: CGFloat {
        let base = UIFont.systemFont(ofSize: beginFontSize)
        let serif = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        let italic = serif.withSymbolicTraits(.traitItalic) ?? serif
        let uiFont = UIFont(descriptor: italic, size: beginFontSize)

        return ceil((text as NSString).size(withAttributes: [.font: uiFont]).width) + 20
    }

    private var parallaxX: CGFloat {
        guard let touchPoint else { return 0 }
        let nx = ((touchPoint.x / areaWidth) - 0.5) * 2.0
        return nx * 6
    }

    private var parallaxY: CGFloat {
        guard let touchPoint else { return 0 }
        let ny = ((touchPoint.y / areaHeight) - 0.5) * 2.0
        return ny * 3
    }

    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: beginFontSize, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.black.opacity(isEnabled ? beginInk : 0.50))
                .frame(width: revealWidth, alignment: .leading)
                .opacity(fadeIn ? 1 : 0)
                .mask(alignment: .leading) {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.78),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(1, (revealWidth * revealProgress) + featherWidth))
                }
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(Color.black.opacity((isEnabled ? beginInk : 0.50) * 0.30))
                        .frame(width: penDotSize, height: penDotSize)
                        .blur(radius: 0.5)
                        .offset(
                            x: max(0, revealWidth * revealProgress - (penDotSize * 0.5)),
                            y: beginFontSize * 0.18
                        )
                        .opacity((revealProgress > 0.02 && revealProgress < 0.99) ? 1 : 0)
                }
                .offset(x: parallaxX, y: parallaxY)
                .animation(.easeOut(duration: 0.22), value: touchPoint?.x)
                .animation(.easeOut(duration: 0.22), value: touchPoint?.y)
        }
        .frame(width: revealWidth + 56, height: 90)
        .allowsHitTesting(false)
        .onAppear {
            animationTask?.cancel()

            if introHasPlayed {
                fadeIn = true
                revealProgress = 1
            } else {
                fadeIn = false
                revealProgress = 0
            }
        }
        .onChange(of: animationSeed) { _, _ in
            startAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func startAnimation() {
        animationTask?.cancel()

        fadeIn = false
        revealProgress = 0

        withAnimation(.easeIn(duration: 0.16)) {
            fadeIn = true
        }

        animationTask = Task { @MainActor in
            let delay = UInt64(writeStartDelay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }

            withAnimation(.linear(duration: writeDuration)) {
                revealProgress = 1
            }
        }
    }
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct LotusPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.10 : 0.0)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.16 : 0.0))
                    .blur(radius: configuration.isPressed ? 12 : 0)
                    .scaleEffect(configuration.isPressed ? 1.08 : 1.0)
            }
            .scaleEffect(configuration.isPressed ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Insights

private struct InsightsCard: View {
    @EnvironmentObject private var capsuleStore: CapsuleStore

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
        Array(insightItems.prefix(3))
    }

    private var visibleLeaningItems: [CapsuleTendency] {
        Array(leaningItems.prefix(3))
    }

    private var visibleShiftItems: [CapsuleTendency] {
        Array(shiftItems.prefix(3))
    }

    private var hasAnything: Bool {
        !insightItems.isEmpty || !leaningItems.isEmpty || !shiftItems.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.headline)
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
