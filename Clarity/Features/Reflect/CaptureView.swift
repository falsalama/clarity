// CaptureView.swift

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct CaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator

    @Environment(\.modelContext) private var modelContext

    let autoPopOnDone: Bool
    let hideDailyQuestion: Bool
    let embedInNavigationStack: Bool
    let onDailyDone: (() -> Void)?
    
    private let cloudTap = CloudTapService()

    @State private var showPermissionAlert: Bool = false
    @State private var permissionAlertTitleKey: String = "perm.title.generic"
    @State private var permissionAlertMessageKey: String = ""

    // Robust navigation path
    @State private var path: [UUID] = []

    // Sheet toggle for typing text
    @State private var showPasteSheet: Bool = false
    @State private var goToDailyFocus = false
    @State private var showDailyAnswerSheet = false

    // Steps (Reflect onboarding)
    @State private var steps: [CloudTapStep] = []
    @State private var stepsError: String? = nil
    @State private var stepsLoading: Bool = false

    // fade in of question card
    @State private var questionReady: Bool = false

    // Captures list (unchanged)
    @Query private var completedTurns: [TurnEntity]
    @State private var bgPhase: Bool = false
    @State private var isReady: Bool = false
    @State private var cloudRevealPoint: CGPoint? = nil
    @State private var cloudRevealAmount: CGFloat = 0

    // Progress count (Reflect done-days)
    @Query private var reflectCompletions: [ReflectCompletionEntity]

    // Singleton state (programme pointer)
    @Query private var reflectState: [ReflectProgramStateEntity]

    init(
        autoPopOnDone: Bool = false,
        hideDailyQuestion: Bool = false,
        embedInNavigationStack: Bool = true,
        onDailyDone: (() -> Void)? = nil
    ) {
        self.autoPopOnDone = autoPopOnDone
        self.hideDailyQuestion = hideDailyQuestion
        self.embedInNavigationStack = embedInNavigationStack
        self.onDailyDone = onDailyDone

        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            },
            sort: [SortDescriptor(\TurnEntity.recordedAt, order: .reverse)]
        )

        _reflectCompletions = Query(
            sort: [SortDescriptor(\ReflectCompletionEntity.completedAt, order: .reverse)]
        )

        _reflectState = Query(
            filter: #Predicate<ReflectProgramStateEntity> { s in
                s.id == "singleton"
            }
        )
    }

    private enum Layout {
        static let headerTopPadding: CGFloat = 4

        static let micSize: CGFloat = 128
        static let micStrokeOpacity: Double = 0.22

        static let badgeTopPadding: CGFloat = 4
        static let badgeTrailingPadding: CGFloat = 4

        static let sectionCorner: CGFloat = 16
        static let cloudRevealSize: CGFloat = 340
    }

    // MARK: - Derived state

    private var todayKey: String {
        let cal = Calendar.current
        let d = cal.startOfDay(for: Date())
        let y = cal.component(.year, from: d)
        let m = cal.component(.month, from: d)
        let day = cal.component(.day, from: d)
        return String(format: "%04d-%02d-%02d", y, m, day)
    }

    private var isDoneToday: Bool {
        reflectCompletions.contains(where: { $0.dayKey == todayKey })
    }

    private var programmeState: ReflectProgramStateEntity? {
        reflectState.first
    }

    private var currentStep: CloudTapStep? {
        guard !steps.isEmpty else { return nil }
        let idx = programmeState?.currentIndex ?? 0
        let clamped = max(0, min(idx, steps.count - 1))
        return steps[clamped]
    }

    var body: some View {
        if embedInNavigationStack {
            NavigationStack(path: $path) {
                captureRoot
            }
        } else {
            captureRoot
        }
    }

    private var captureRoot: some View {
        ZStack {
            captureBackground

            if hideDailyQuestion {
                List {
                    captureSurfaceSection
                    capturesSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .opacity(isReady ? 1 : 0)
                .animation(.easeOut(duration: 0.55), value: isReady)
                .padding(.top, -52)
            } else {
                dailyCaptureLayout
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Reflect")
                        .font(.headline)

                    if hideDailyQuestion {
                        Text("express yourself honestly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            TurnDetailView(turnID: id)
        }
        .navigationDestination(isPresented: $goToDailyFocus) {
            FocusView()
        }
        .onChange(of: coordinator.lastCompletedTurnID) { _, newValue in
            guard let id = newValue else { return }
            guard coordinator.isCarPlayConnected == false else { return }

            coordinator.clearLiveTranscript()
            path.append(id)
            coordinator.lastCompletedTurnID = nil
        }
        .onChange(of: coordinator.uiError) { _, newValue in
            guard let err = newValue else { return }

            switch err {
            case .micDenied, .micNotGranted:
                permissionAlertTitleKey = "perm.mic.title"
                permissionAlertMessageKey = "perm.mic.message"
                showPermissionAlert = true
            case .speechDeniedOrNotAuthorised, .speechUnavailable:
                permissionAlertTitleKey = "perm.speech.title"
                permissionAlertMessageKey = "perm.speech.message"
                showPermissionAlert = true
            default:
                break
            }
        }
        .alert(
            Text(LocalizedStringKey(permissionAlertTitleKey)),
            isPresented: $showPermissionAlert
        ) {
            Button(String(localized: "perm.button.open_settings")) { openAppSettings() }
            Button(String(localized: "perm.button.cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey(permissionAlertMessageKey))
        }
        .sheet(isPresented: $showPasteSheet) {
            PasteTextTurnSheet { newID in
                path.append(newID)
            }
            .environmentObject(coordinator)
        }
        .onAppear {
            bgPhase.toggle()
            isReady = false
            ensureProgrammeState()

            Task {
                await MainActor.run {
                    advanceIfPending()
                    withAnimation(.easeOut(duration: 0.28)) {
                        isReady = true
                    }
                }

                await loadStepsIfNeeded()
            }
        }
        .onChange(of: todayKey) { _, _ in
            // New calendar day: advance if yesterday was marked done.
            advanceIfPending()
        }
        .sheet(isPresented: $showDailyAnswerSheet) {
            DailyReflectAnswerSheet(step: currentStep, dayKey: todayKey) {
                // Stay on the daily reflect screen after saving.
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
        }
    }

    private var captureBackground: some View {
        GeometryReader { proxy in
            ZStack {
                if let cloudRevealPoint {
                    skyRevealFill(in: proxy)
                        .opacity(cloudRevealAmount * 0.98)
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
                                            endRadius: Layout.cloudRevealSize * (0.56 + (cloudRevealAmount * 0.14))
                                        )
                                    )
                                    .frame(
                                        width: Layout.cloudRevealSize * (1.04 + cloudRevealAmount * 0.10),
                                        height: Layout.cloudRevealSize * (1.04 + cloudRevealAmount * 0.10)
                                    )
                                    .position(cloudRevealPoint)
                                    .blur(radius: 30)
                            }
                            .compositingGroup()
                        }
                        .overlay {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color(red: 0.73, green: 0.84, blue: 0.97).opacity(0.14),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: Layout.cloudRevealSize * 0.34
                                    )
                                )
                                .frame(width: Layout.cloudRevealSize * 0.72, height: Layout.cloudRevealSize * 0.72)
                                .position(cloudRevealPoint)
                                .opacity(cloudRevealAmount * 0.55)
                                .blur(radius: 20)
                        }
                }

                cloudsBackgroundImage(named: "CloudsBG", in: proxy, imageOpacity: 0.30)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func skyRevealFill(in proxy: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.89, blue: 0.99),
                    Color(red: 0.88, green: 0.94, blue: 0.99),
                    Color(red: 0.97, green: 0.98, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.36),
                    Color(red: 0.72, green: 0.86, blue: 0.98).opacity(0.26),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 0.52
            )
            .blendMode(.screen)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }

    private func cloudsBackgroundImage(named name: String, in proxy: GeometryProxy, imageOpacity: Double) -> some View {
        return Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
            .opacity(imageOpacity)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: .black, location: 0.14),
                        .init(color: .black, location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .scaleEffect(bgPhase ? 1.30 : 1.18, anchor: .bottom)
            .scaleEffect(x: -1, y: 1)
            .offset(y: bgPhase ? 72 : 92)
    }

    // MARK: - Steps: load + state

    private func ensureProgrammeState() {
        guard programmeState == nil else { return }
        let s = ReflectProgramStateEntity()
        modelContext.insert(s)
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private func loadStepsIfNeeded() async {
        guard steps.isEmpty, stepsLoading == false else { return }
        stepsLoading = true
        stepsError = nil
        questionReady = false
        do {
            let resp = try await cloudTap.reflectSteps(programme: "starter_5day")
            await MainActor.run {
                self.steps = resp.steps
                self.stepsLoading = false
                self.stepsError = resp.steps.isEmpty ? "No steps returned." : nil
                self.questionReady = !resp.steps.isEmpty
            }
        } catch {
            await MainActor.run {
                self.stepsLoading = false
                self.stepsError = "Couldn’t load today’s question."
                self.questionReady = true
            }
        }
    }

    private var canRepairTodaySnapshot: Bool {
        #if DEBUG
        guard isDoneToday else { return false }
        let existing = reflectCompletions.first(where: { $0.dayKey == todayKey })
        let titleEmpty = (existing?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyEmpty  = (existing?.body  ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (titleEmpty && bodyEmpty) && (currentStep != nil)
        #else
        return false
        #endif
    }

    private func advanceIfPending() {
        guard let s = programmeState else { return }
        guard let pending = s.pendingAdvanceDayKey else { return }
        guard pending != todayKey else { return } // only advance on a new day after Done
        guard !steps.isEmpty else { return }

        s.currentIndex = min(s.currentIndex + 1, steps.count - 1)
        s.pendingAdvanceDayKey = nil
        s.updatedAt = Date()
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private var dailyAnswerTurnIDToday: UUID? {
        let cal = Calendar.current
        let now = Date()

        return completedTurns.first(where: { turn in
            cal.isDate(turn.recordedAt, inSameDayAs: now) &&
            turn.promptKindRaw == "daily_reflect" &&
            turn.promptDayKey == todayKey
        })?.id
    }

    private func applyDailyPromptSnapshot(to turnID: UUID?) {
        guard let turnID else { return }
        guard let step = currentStep else { return }
        guard let turn = completedTurns.first(where: { $0.id == turnID }) else { return }

        turn.promptKindRaw = "daily_reflect"
        turn.promptProgrammeSlug = "starter_5day"
        turn.promptStepIndex = step.stepIndex
        turn.promptTitle = step.title
        turn.promptBody = step.body
        turn.promptDayKey = todayKey
    }
    
    private func markDoneToday() {
        let step = currentStep
        let linkedTurnID = dailyAnswerTurnIDToday

        applyDailyPromptSnapshot(to: linkedTurnID)

        if let existing = reflectCompletions.first(where: { $0.dayKey == todayKey }) {
            existing.turnId = linkedTurnID
            existing.programmeSlug = nil
            existing.stepIndex = step?.stepIndex
            existing.title = step?.title
            existing.body = step?.body
            existing.completedAt = existing.completedAt

            if let s = programmeState {
                s.pendingAdvanceDayKey = todayKey
                s.updatedAt = Date()
            }

            do { try modelContext.save() } catch { /* best-effort */ }
            return
        }

        let completion = ReflectCompletionEntity(
            turnId: linkedTurnID,
            dayKey: todayKey,
            completedAt: Date(),
            programmeSlug: nil,
            stepIndex: step?.stepIndex,
            title: step?.title,
            body: step?.body
        )
        modelContext.insert(completion)

        if let s = programmeState {
            s.pendingAdvanceDayKey = todayKey
            s.updatedAt = Date()
        }

        do { try modelContext.save() } catch { /* best-effort */ }
    }
    // MARK: - Sections

    private var captureSurfaceSection: some View {
        VStack(spacing: 12) {
            reflectExplainerCard
            SharedCaptureSurfaceView(
                showPromptChips: false,
                showTypeButton: true,
                onTypeTap: { showPasteSheet = true }
            )
        }
        .padding(.vertical, 0)
        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 10, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var dailyCaptureLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                dailyQuestionCard
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .frame(minHeight: geo.size.height, alignment: .top)
            .opacity(isReady ? 1 : 0)
            .animation(.easeOut(duration: 0.28), value: isReady)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        cloudRevealPoint = value.location
                        withAnimation(.easeOut(duration: 0.14)) {
                            cloudRevealAmount = 1
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.85)) {
                            cloudRevealAmount = 0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            if cloudRevealAmount == 0 {
                                cloudRevealPoint = nil
                            }
                        }
                    }
            )
        }
    }

    private var hasAnswerToday: Bool {
        dailyAnswerTurnIDToday != nil
    }

    private var dailyVoiceActionTitle: String {
        switch coordinator.phase {
        case .idle:
            return "Answer"
        case .recording:
            return "Stop"
        case .preparing:
            return "Preparing…"
        case .finalising:
            return "Finalising…"
        case .transcribing:
            return "Transcribing…"
        case .redacting:
            return "Saving…"
        }
    }

    private var dailyVoiceActionEnabled: Bool {
        coordinator.phase == .idle || coordinator.phase == .recording
    }

    private var dailyPhaseStatusText: String {
        switch coordinator.phase {
        case .preparing:
            return "Preparing…"
        case .recording:
            return "Listening…"
        case .finalising:
            return "Finalising…"
        case .transcribing:
            return "Transcribing…"
        case .redacting:
            return "Saving…"
        case .idle:
            return ""
        }
    }

    private var dailyQuestionCard: some View {
        VStack(spacing: 18) {
            Text("Today’s question")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Group {
                if stepsLoading {
                    Text("Loading…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                } else if let err = stepsError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                } else if let step = currentStep {
                    Text(step.body)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(questionReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.24), value: questionReady)

                } else {
                    Text("No question yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .transaction { $0.animation = nil }
            VStack(alignment: .leading, spacing: 14) {
                Text("Answer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                SharedCaptureSurfaceView(
                    showPromptChips: false,
                    showTypeButton: true,
                    onTypeTap: { showDailyAnswerSheet = true }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if hasAnswerToday {
                Button {
                    markDoneToday()

                    if let onDailyDone {
                        onDailyDone()
                    } else if autoPopOnDone {
                        goToDailyFocus = true
                    }
                } label: {
                    Text("Done")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(
                    isDoneToday ||
                    !hasAnswerToday ||
                    coordinator.phase != .idle ||
                    currentStep == nil
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        )
    }

    private var reflectExplainerCard: some View {
        VStack(spacing: 10) {
            Text("Speak or type what’s on your mind.")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var capturesSection: some View {
        Section {
            let items: [TurnEntity] = Array(completedTurns.prefix(25))
            if items.isEmpty {
                Text("Nothing here yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(items) { t in
                    NavigationLink(value: t.id) {
                        captureRow(t)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTurn(t)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            starTurn(t)
                        } label: {
                            Label(
                                t.isStarred ? "Unstar" : "Star",
                                systemImage: t.isStarred ? "star.slash" : "star"
                            )
                        }
                        .tint(.yellow)
                    }
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(.secondary.opacity(0.45))
                }
            }
        } header: {
            HStack {
                Text("Captures")
                Spacer()
                Text("\(completedTurns.count)")
                    .foregroundStyle(.secondary)
            }
            .font(.headline)
            .textCase(nil)
        }
    }

   

    // MARK: - Capture row

    private func captureRow(_ t: TurnEntity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title(for: t))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if t.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }

            let preview = t.transcriptRedactedActive.trimmingCharacters(in: .whitespacesAndNewlines)
            if !preview.isEmpty {
                Text(preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private func title(for t: TurnEntity) -> String {
        let v = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "Capture" : v
    }

    // MARK: - Swipe actions

    private func deleteTurn(_ t: TurnEntity) {
        modelContext.delete(t)
        do { try modelContext.save() } catch { /* keep silent for now */ }
    }

    private func starTurn(_ t: TurnEntity) {
        t.isStarred.toggle()
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    private func openAppSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

private struct DailyReflectAnswerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var capsuleStore: CapsuleStore

    @State private var text: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false
    @FocusState private var isEditorFocused: Bool

    let step: CloudTapStep?
    let dayKey: String
    let onCreated: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Answer")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .textSelection(.enabled)
                    .frame(minHeight: 280)

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Type answer here")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }

            HStack {
                Spacer(minLength: 0)

                Button(isSaving ? "Saving…" : "Save") {
                    save()
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isEditorFocused = true
            }
        }
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Text is empty."
            return
        }

        let redacted = Redactor(tokens: dictionary.tokens).redact(input).redactedText

        do {
            let repo = TurnRepository(context: modelContext)
            let id = try repo.createTextTurn(
                redactedText: redacted,
                recordedAt: Date(),
                captureContext: .unknown
            )

            if let t = try? repo.fetch(id: id) {
                t.promptKindRaw = "daily_reflect"
                t.promptProgrammeSlug = "starter_5day"
                t.promptStepIndex = step?.stepIndex
                t.promptTitle = step?.title
                t.promptBody = step?.body
                t.promptDayKey = dayKey

                if t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let auto = autoTitle(from: redacted), !auto.isEmpty {
                    t.title = auto
                }

                try? modelContext.save()
            }

            _ = try TraceEngine.processSavedTurn(
                turnID: id,
                redactedText: redacted,
                repo: repo,
                modelContext: modelContext,
                capsuleStore: capsuleStore,
                learningAllowed: true,
                now: Date()
            )

            onCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func autoTitle(from text: String) -> String? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let words = cleaned
            .split(whereSeparator: \.isWhitespace)
            .prefix(7)
            .map(String.init)

        let title = words.joined(separator: " ")
        let capped = String(title.prefix(56))
        return capped.isEmpty ? nil : capped
    }
}

#Preview {
    CaptureView()
        .environmentObject(TurnCaptureCoordinator())
        .environmentObject(AppFlowRouter())
}
