import SwiftUI
import AVFoundation
import AudioToolbox
import UIKit

struct MeditationZoneView: View {
    @AppStorage("meditation.selectedMinutes") private var selectedMinutes = 1
    @AppStorage("meditation.useCustomDuration") private var useCustomDuration = false
    @AppStorage("meditation.customMinutes") private var customMinutes = 1
    @AppStorage("meditation.playStartBell") private var playStartBell = true
    @AppStorage("meditation.playEndBell") private var playEndBell = true
    @AppStorage("meditation.totalCompletedSeconds") private var totalCompletedSeconds = 0

    @State private var isRunning = false
    @State private var totalSeconds = 60
    @State private var secondsRemaining = 60
    @State private var endDate: Date?

    @State private var activeSheet: MeditationSupportSheet?
    @StateObject private var healthKit = HealthKitManager()
    @State private var sessionStartDate: Date?
    @State private var bellPlayer: AVAudioPlayer?
    @State private var bellFadeTask: Task<Void, Never>?
    @State private var timer: Timer?
    @State private var bowlGlow = false
    @State private var idleRingProgress = 1.0
    @State private var holdCompletedColorOverlay = false

    private let presets = [1, 3, 5, 10, 15, 20]
    private let medbgMaxOpacity = 0.24
    private let medcolbgMaxOpacity = 0.36

    private var resolvedMinutes: Int {
        useCustomDuration ? max(1, customMinutes) : max(1, selectedMinutes)
    }

    private var backgroundImageName: String {
        resolvedMinutes == 10 ? "medVYbg" : "medbg"
    }

    private var colorOverlayImageName: String {
        resolvedMinutes == 10 ? "medVYcolbg" : "medcolbg"
    }

    private func remainingTimeInterval(at date: Date) -> TimeInterval {
        guard isRunning, let endDate else { return TimeInterval(secondsRemaining) }
        return max(0, endDate.timeIntervalSince(date))
    }

    private func progress(at date: Date) -> Double {
        guard totalSeconds > 0 else { return 1 }
        return remainingTimeInterval(at: date) / Double(totalSeconds)
    }

    private func sessionElapsedProgress(at date: Date) -> Double {
        guard isRunning, totalSeconds > 0 else { return 0 }
        return 1 - progress(at: date)
    }

    private func ringSilverBlend(at date: Date) -> Double {
        let elapsedProgress = sessionElapsedProgress(at: date)

        if elapsedProgress <= 0.5 {
            return elapsedProgress / 0.5
        } else {
            return 1 - ((elapsedProgress - 0.5) / 0.5)
        }
    }

    private func blendedRingColor(
        gold: (Double, Double, Double),
        silver: (Double, Double, Double),
        blend: Double
    ) -> Color {
        Color(
            red: gold.0 + ((silver.0 - gold.0) * blend),
            green: gold.1 + ((silver.1 - gold.1) * blend),
            blue: gold.2 + ((silver.2 - gold.2) * blend)
        )
    }

    private func sessionBackgroundOpacity(at date: Date) -> Double {
        guard
            isRunning,
            totalSeconds > 0
        else {
            return 0
        }

        let elapsedProgress = sessionElapsedProgress(at: date)
        let fadeInCompletionProgress = 0.45
        let crossFadeStartProgress = 0.5
        let fadeInOpacity = min(1, elapsedProgress / fadeInCompletionProgress) * medbgMaxOpacity

        guard elapsedProgress > crossFadeStartProgress else { return fadeInOpacity }

        let fadeOutProgress = 1 - min(
            1,
            (elapsedProgress - crossFadeStartProgress) / (1 - crossFadeStartProgress)
        )
        return fadeInOpacity * fadeOutProgress
    }

    private func sessionColorOverlayOpacity(at date: Date) -> Double {
        if holdCompletedColorOverlay {
            return medcolbgMaxOpacity
        }

        guard
            isRunning,
            totalSeconds > 0
        else {
            return 0
        }

        let elapsedProgress = sessionElapsedProgress(at: date)
        let crossFadeStartProgress = 0.5

        guard elapsedProgress > crossFadeStartProgress else { return 0 }

        let fadeProgress = min(
            1,
            (elapsedProgress - crossFadeStartProgress) / (1 - crossFadeStartProgress)
        )
        return fadeProgress * medcolbgMaxOpacity
    }

    private func bowlOpacity(at date: Date) -> Double {
        guard
            isRunning,
            let sessionStartDate
        else {
            return 1
        }

        let minimumOpacity = 0.0
        let fadeOutDelay: TimeInterval = 2
        let fadeOutDuration: TimeInterval = 10
        let fadeBackWindow: TimeInterval = 6

        let elapsed = max(0, date.timeIntervalSince(sessionStartDate))
        let remaining = remainingTimeInterval(at: date)

        let fadeOutProgress = min(max((elapsed - fadeOutDelay) / fadeOutDuration, 0), 1)
        let fadedOpacity = 1 - (fadeOutProgress * (1 - minimumOpacity))

        guard remaining < fadeBackWindow else { return fadedOpacity }

        let fadeBackProgress = 1 - (remaining / fadeBackWindow)
        return fadedOpacity + ((1 - fadedOpacity) * fadeBackProgress)
    }

    private var totalMeditationText: String {
        let hours = totalCompletedSeconds / 3600
        let minutes = (totalCompletedSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func controlsOpacity(at date: Date) -> Double {
        guard
            isRunning,
            let sessionStartDate
        else {
            return 1
        }

        let fadeOutDuration: TimeInterval = 1.4
        let fadeBackWindow: TimeInterval = 8

        let elapsed = max(0, date.timeIntervalSince(sessionStartDate))
        let fadeOutOpacity = 1 - min(max(elapsed / fadeOutDuration, 0), 1)

        let remaining = remainingTimeInterval(at: date)
        let fadeBackOpacity: Double
        if remaining < fadeBackWindow {
            fadeBackOpacity = 1 - (remaining / fadeBackWindow)
        } else {
            fadeBackOpacity = 0
        }

        return max(fadeOutOpacity, fadeBackOpacity)
    }

    private func titleOpacity(at date: Date) -> Double {
        0.18 + (controlsOpacity(at: date) * 0.82)
    }

    private func tabBarOpacity(at date: Date) -> Double {
        0.32 + (controlsOpacity(at: date) * 0.68)
    }

    @ViewBuilder
    private var timerCardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.clear)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let now = context.date
            let controlsOpacity = controlsOpacity(at: now)
            let titleOpacity = titleOpacity(at: now)
            let tabBarOpacity = tabBarOpacity(at: now)
            let screenBounds = UIScreen.main.bounds

            ZStack {
                Image(backgroundImageName)
                    .resizable(resizingMode: .stretch)
                    .frame(width: screenBounds.width, height: screenBounds.height)
                    .opacity(sessionBackgroundOpacity(at: now))
                    .ignoresSafeArea()

                Image(colorOverlayImageName)
                    .resizable(resizingMode: .stretch)
                    .frame(width: screenBounds.width, height: screenBounds.height)
                    .opacity(sessionColorOverlayOpacity(at: now))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerBlock
                            .opacity(controlsOpacity)

                        timerCard(controlsOpacity: controlsOpacity, now: now)

                        supportGrid
                            .opacity(controlsOpacity)
                            .allowsHitTesting(!isRunning)

                        closingCard
                            .opacity(controlsOpacity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 124)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Meditation Zone")
                        .font(.headline.weight(.semibold))
                        .opacity(titleOpacity)
                }
            }
            .background(TabBarOpacityBridge(opacity: tabBarOpacity))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .sheet(item: $activeSheet) { sheet in
            MeditationSupportSheetView(sheet: sheet)
                .presentationDetents([.large])
        }
        .onAppear {
            syncDurationIfIdle()
            healthKit.refreshAuthorizationState()
        }
        .onDisappear {
            resetSession()
        }
        .onChange(of: selectedMinutes) { _, _ in
            syncDurationIfIdle()
        }
        .onChange(of: customMinutes) { _, _ in
            syncDurationIfIdle()
        }
        .onChange(of: useCustomDuration) { _, _ in
            syncDurationIfIdle()
        }
    }

    private var headerBlock: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meditation")
                    .font(.title2.weight(.semibold))

                Text("Sit, settle, return")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(totalMeditationText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(.top, 4)
    }

    private func timerCard(controlsOpacity: Double, now: Date) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timer")
                        .font(.headline)

                    Text("Choose a length, then tap the bowl.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .opacity(controlsOpacity)

            bowlTimerButton(now: now, controlsOpacity: controlsOpacity)

            durationSection
                .opacity(controlsOpacity)
                .allowsHitTesting(!isRunning)

            VStack(spacing: 12) {
                Toggle("Ring at the start", isOn: $playStartBell)
                Toggle("Ring at the end", isOn: $playEndBell)
            }
            .tint(Color(red: 0.44, green: 0.56, blue: 0.50))
            .opacity(controlsOpacity)
            .allowsHitTesting(!isRunning)

            Button {
                resetSession()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.10))
                    )
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(isRunning)
            .opacity(controlsOpacity)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .background(timerCardBackground)
        .animation(.easeInOut(duration: 0.45), value: isRunning)
    }

    private func bowlTimerButton(now: Date, controlsOpacity: Double) -> some View {
        Button {
            if isRunning {
                stopSession()
            } else {
                startSession()
            }
        } label: {
            let liveProgress = isRunning ? progress(at: now) : idleRingProgress
            let silverBlend = ringSilverBlend(at: now)
            let ringStartColor = blendedRingColor(
                gold: (0.78, 0.64, 0.20),
                silver: (0.84, 0.86, 0.90),
                blend: silverBlend
            )
            let ringMidColor = blendedRingColor(
                gold: (0.95, 0.83, 0.34),
                silver: (0.97, 0.98, 1.00),
                blend: silverBlend
            )
            let ringEndColor = blendedRingColor(
                gold: (0.78, 0.64, 0.20),
                silver: (0.84, 0.86, 0.90),
                blend: silverBlend
            )
            let ringShadowColor = blendedRingColor(
                gold: (0.90, 0.76, 0.28),
                silver: (0.88, 0.90, 0.96),
                blend: silverBlend
            )

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 18)
                    .frame(width: 290, height: 290)

                Circle()
                    .trim(from: 0, to: liveProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                ringStartColor,
                                ringMidColor,
                                ringEndColor
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 290, height: 290)
                    .shadow(
                        color: ringShadowColor.opacity(bowlGlow ? 0.22 : 0.08),
                        radius: bowlGlow ? 16 : 6
                    )

                Image("singing-bowl")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 145)
                    .scaleEffect(bowlGlow ? 1.01 : 1.0)
                    .shadow(
                        color: Color(red: 0.90, green: 0.76, blue: 0.28).opacity(bowlGlow ? 0.18 : 0.06),
                        radius: bowlGlow ? 16 : 6,
                        y: bowlGlow ? 6 : 3
                    )
                    .animation(
                        isRunning
                        ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true)
                        : .easeOut(duration: 0.25),
                        value: bowlGlow
                    )
                    .opacity(bowlOpacity(at: now))

                VStack {
                    Spacer()

                    Text(isRunning ? "Tap bowl to end session" : "Tap bowl to begin session")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 56)
                        .opacity(controlsOpacity)
                }
                .frame(width: 290, height: 290)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 66), spacing: 10)],
                spacing: 10
            ) {
                ForEach(presets, id: \.self) { minutes in
                    Button {
                        useCustomDuration = false
                        selectedMinutes = minutes
                    } label: {
                        Text("\(minutes)m")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(!useCustomDuration && selectedMinutes == minutes ? Color.primary.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(!useCustomDuration && selectedMinutes == minutes ? Color.primary.opacity(0.20) : Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle("Custom duration", isOn: $useCustomDuration)
                .toggleStyle(.switch)

            if useCustomDuration {
                Stepper(value: $customMinutes, in: 1...120) {
                    HStack {
                        Text("Custom length")
                        Spacer()
                        Text("\(customMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var supportGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.title3.weight(.semibold))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                supportButton(
                    title: "Posture",
                    subtitle: "Sit well",
                    systemImage: "figure.mind.and.body"
                ) {
                    activeSheet = .posture
                }

                supportButton(
                    title: "Shamatha",
                    subtitle: "Shyiné basics",
                    systemImage: "wind"
                ) {
                    activeSheet = .shamatha
                }

                supportButton(
                    title: "Tips",
                    subtitle: "Keep it simple",
                    systemImage: "lightbulb"
                ) {
                    activeSheet = .tips
                }

                supportButton(
                    title: "Recitation",
                    subtitle: "Optional lane",
                    systemImage: "text.quote"
                ) {
                    activeSheet = .recitation
                }
            }
        }
    }

    private var closingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why this space")
                .font(.headline)

            Text("The point is steadiness, clarity, and insight. Completed Meditation Zone sessions can also be saved to Apple Health as mindful minutes.")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func supportButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.44, green: 0.56, blue: 0.50))

                Spacer(minLength: 0)

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func syncDurationIfIdle() {
        guard !isRunning else { return }
        totalSeconds = resolvedMinutes * 60
        secondsRemaining = totalSeconds
    }

    private func startSession() {
        holdCompletedColorOverlay = false
        idleRingProgress = 1
        let start = Date()
        sessionStartDate = start
        totalSeconds = resolvedMinutes * 60
        secondsRemaining = totalSeconds
        endDate = start.addingTimeInterval(TimeInterval(totalSeconds))
        isRunning = true
        bowlGlow = true

        if playStartBell {
            ringBell()
        }

        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            tick()
        }
    }

    private func stopSession() {
        holdCompletedColorOverlay = false
        stopBell()
        invalidateTimer()
        isRunning = false
        bowlGlow = false
        endDate = nil
        sessionStartDate = nil
        idleRingProgress = 1
        syncDurationIfIdle()
    }

    private func resetSession() {
        let shouldAnimateRingReset = !isRunning && secondsRemaining == 0

        holdCompletedColorOverlay = false
        stopBell()
        invalidateTimer()
        isRunning = false
        bowlGlow = false
        endDate = nil
        sessionStartDate = nil
        totalSeconds = resolvedMinutes * 60
        secondsRemaining = totalSeconds

        if shouldAnimateRingReset {
            withAnimation(.easeInOut(duration: 0.9)) {
                idleRingProgress = 1
            }
        } else {
            idleRingProgress = 1
        }
    }

    private func tick() {
        guard isRunning, let endDate else { return }

        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        secondsRemaining = remaining

        if remaining <= 0 {
            finishSession()
        }
    }

    private func finishSession() {
        invalidateTimer()

        let completedEnd = Date()
        let completedStart = sessionStartDate ?? completedEnd.addingTimeInterval(-TimeInterval(totalSeconds))

        isRunning = false
        bowlGlow = false
        endDate = nil
        sessionStartDate = nil
        secondsRemaining = 0
        idleRingProgress = 0
        holdCompletedColorOverlay = true

        totalCompletedSeconds += totalSeconds

        if playEndBell {
            ringBell(
                volume: 0.42,
                fadeOutAfter: 2.5,
                fadeOutDuration: 2.5,
                totalDuration: 5
            )
        }

        Task {
            _ = await healthKit.saveMindfulSession(start: completedStart, end: completedEnd)
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    private func stopBell() {
        bellFadeTask?.cancel()
        bellFadeTask = nil
        bellPlayer?.stop()
        bellPlayer?.currentTime = 0
        bellPlayer = nil
    }
    private func ringBell(
        volume: Float = 1.0,
        fadeOutAfter: TimeInterval? = nil,
        fadeOutDuration: TimeInterval = 0,
        totalDuration: TimeInterval? = nil
    ) {
        if let url = Bundle.main.url(forResource: "singing-bowl", withExtension: "m4a") {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)

                bellFadeTask?.cancel()
                bellPlayer = try AVAudioPlayer(contentsOf: url)
                bellPlayer?.volume = volume
                bellPlayer?.prepareToPlay()
                bellPlayer?.play()

                if
                    let fadeOutAfter,
                    let totalDuration,
                    let player = bellPlayer
                {
                    bellFadeTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(fadeOutAfter * 1_000_000_000))
                        guard bellPlayer === player else { return }
                        player.setVolume(0, fadeDuration: fadeOutDuration)

                        let remainingDuration = max(0, totalDuration - fadeOutAfter)
                        try? await Task.sleep(nanoseconds: UInt64(remainingDuration * 1_000_000_000))
                        guard bellPlayer === player else { return }
                        player.stop()
                        player.currentTime = 0
                        bellPlayer = nil
                        bellFadeTask = nil
                    }
                }
                return
            } catch {
            }
        }

        AudioServicesPlaySystemSound(1104)
    }
}

private struct TabBarOpacityBridge: UIViewControllerRepresentable {
    let opacity: Double

    func makeUIViewController(context: Context) -> UIViewController {
        Controller()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? Controller)?.updateOpacity(opacity)
    }

    private final class Controller: UIViewController {
        private var appliedOpacity: CGFloat = 1

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            applyOpacity()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            tabBarController?.tabBar.alpha = 1
        }

        func updateOpacity(_ opacity: Double) {
            appliedOpacity = CGFloat(opacity)
            applyOpacity()
        }

        private func applyOpacity() {
            tabBarController?.tabBar.alpha = appliedOpacity
        }
    }
}

private enum MeditationSupportSheet: String, Identifiable {
    case posture
    case shamatha
    case tips
    case recitation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posture:
            return "Posture"
        case .shamatha:
            return "Shamatha (Shyiné)"
        case .tips:
            return "Tips"
        case .recitation:
            return "Daily recitation"
        }
    }
}

private struct MeditationSupportSheetView: View {
    let sheet: MeditationSupportSheet

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(sheet.title)
                    .font(.title3.weight(.semibold))

                switch sheet {
                case .posture:
                    sheetLine("Sit on a chair, cushion, or bench with a stable base.")
                    sheetLine("Keep the spine upright but not stiff.")
                    sheetLine("Let the shoulders drop and the jaw soften.")
                    sheetLine("Rest the hands simply and let the belly be easy.")
                    sheetLine("Let the gaze be natural. No strain.")

                case .shamatha:
                    sheetLine("Shamatha and shyiné are the same basic calm abiding practice.")
                    sheetLine("Let attention rest lightly with the breath.")
                    sheetLine("When distracted, notice it and return gently.")
                    sheetLine("Do not fight thoughts. Do not chase blankness.")
                    sheetLine("Short, regular sessions are better than forcing.")

                case .tips:
                    sheetLine("Keep the session short enough that you will actually do it.")
                    sheetLine("Thoughts are not failure.")
                    sheetLine("Restlessness is normal.")
                    sheetLine("If you feel overloaded, stop and ground yourself.")
                    sheetLine("The point is familiarity, not performance.")

                case .recitation:
                    sheetLine("Possible daily recitation options:")
                    sheetLine("Refuge")
                    sheetLine("Heart Sutra")
                    sheetLine("Chenrezig")
                    sheetLine("Tara")
                    sheetLine("Manjushri")
                    sheetLine("Keep this optional and brief. We can wire the actual texts cleanly next.")
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .presentationDragIndicator(.visible)
    }

    private func sheetLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .foregroundStyle(.primary)
        }
    }
}

private extension Int {
    var clockString: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
