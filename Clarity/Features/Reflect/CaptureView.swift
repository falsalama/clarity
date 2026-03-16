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
            cloudsBackground

            List {
                captureSurfaceSection
                capturesSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .opacity(isReady ? 1 : 0)
            .animation(.easeOut(duration: 0.55), value: isReady)
            .padding(.top, hideDailyQuestion ? -52 : 0)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Reflect")
                        .font(.headline)
                    Text("express yourself honestly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
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
                await loadStepsIfNeeded()
                await MainActor.run {
                    advanceIfPending()
                    withAnimation(.easeOut(duration: 0.55)) {
                        isReady = true
                    }
                }
            }
        }
        .onChange(of: todayKey) { _, _ in
            // New calendar day: advance if yesterday was marked done.
            advanceIfPending()
        }
    }

    private var cloudsBackground: some View {
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
            .scaleEffect(bgPhase ? 1.30 : 1.18, anchor: .bottom)
            .scaleEffect(x: -1, y: 1) // mirror horizontally
            .offset(y: bgPhase ? 98 : 120)
            .allowsHitTesting(false)
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

    private var latestTurnIDToday: UUID? {
        let cal = Calendar.current
        let now = Date()

        return completedTurns.first(where: { turn in
            cal.isDate(turn.recordedAt, inSameDayAs: now)
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
        let linkedTurnID = latestTurnIDToday

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

            if hideDailyQuestion {
                reflectExplainerCard
            } else {
                todayQuestionCard
            }

            SharedCaptureSurfaceView(
                showPromptChips: true,
                showTypeButton: true,
                onTypeTap: { showPasteSheet = true }
            )
        }
        .padding(.vertical, 0)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    private var todayQuestionCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Today’s question")
                .font(.title3.weight(.semibold))

            Group {
                if stepsLoading {
                    Text("Loading…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                } else if let err = stepsError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                } else if let step = currentStep {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.body)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Press mic or type to answer. Speaking is recommended.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(questionReady ? 1 : 0)
                    .animation(.easeOut(duration: 0.55), value: questionReady)

                } else {
                    Text("No question yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .transaction { $0.animation = nil }

            Divider()
                .padding(.top, 6)

            HStack {
                Text(isDoneToday ? "Done for today, come back tomorrow." : "Mark as done for today.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

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
                }
                .buttonStyle(.bordered)
                .disabled(
                    isDoneToday ||
                    coordinator.phase != .idle ||
                    currentStep == nil
                )
            }

            #if DEBUG
            if canRepairTodaySnapshot {
                Button("Repair snapshot (debug)") {
                    markDoneToday()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            }
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.sectionCorner, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var reflectExplainerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reflect")
                .font(.title3.weight(.semibold))

            Text("Use this to speak or type what is on your mind. Use the buttons below for structured reflection through a Buddhist lens.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().padding(.top, 6)

            Text("Tip: Keep it short. One clear thought is enough.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview {
    CaptureView()
        .environmentObject(TurnCaptureCoordinator())
        .environmentObject(AppFlowRouter())
}
