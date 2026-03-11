import SwiftUI
import AVFoundation
import AudioToolbox

struct MeditationZoneView: View {
    @Environment(\.colorScheme) private var colorScheme

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
    @State private var timer: Timer?
    @State private var bowlStrike = false
    @State private var bowlGlow = false

    private let presets = [1, 3, 5, 10, 15, 20]

    private var resolvedMinutes: Int {
        useCustomDuration ? max(1, customMinutes) : max(1, selectedMinutes)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return Double(secondsRemaining) / Double(totalSeconds)
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
    
    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.12),
                    Color(red: 0.11, green: 0.10, blue: 0.09),
                    Color(red: 0.10, green: 0.12, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.93),
                    Color(red: 0.93, green: 0.92, blue: 0.88),
                    Color(red: 0.91, green: 0.94, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerBlock
                timerCard
                supportGrid
                closingCard
            }
            .padding(16)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Meditation Zone")
        .navigationBarTitleDisplayMode(.inline)
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

    private var timerCard: some View {
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

            bowlTimerButton

            if isRunning {
                Text("Tap the bowl to end the session at any point.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            durationSection

            VStack(spacing: 12) {
                Toggle("Ring at the start", isOn: $playStartBell)
                Toggle("Ring at the end", isOn: $playEndBell)
            }
            .tint(Color(red: 0.44, green: 0.56, blue: 0.50))

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
            .opacity(isRunning ? 0.45 : 1)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var bowlTimerButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.12)) {
                bowlStrike = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.22)) {
                    bowlStrike = false
                }
            }

            if isRunning {
                stopSession()
            } else {
                startSession()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 18)
                    .frame(width: 290, height: 290)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.78, green: 0.64, blue: 0.20),
                                Color(red: 0.95, green: 0.83, blue: 0.34),
                                Color(red: 0.78, green: 0.64, blue: 0.20)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 290, height: 290)
                    .shadow(
                        color: Color(red: 0.90, green: 0.76, blue: 0.28).opacity(bowlGlow ? 0.22 : 0.08),
                        radius: bowlGlow ? 16 : 6
                    )
                    .animation(.easeInOut(duration: 0.35), value: secondsRemaining)

                VStack(spacing: 2) {
                    Image("singing-bowl")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 145)
                        .scaleEffect(bowlStrike ? 0.985 : (bowlGlow ? 1.01 : 1.0))
                        .rotationEffect(.degrees(bowlStrike ? -0.8 : 0))
                        .shadow(
                            color: Color(red: 0.90, green: 0.76, blue: 0.28).opacity(bowlGlow ? 0.18 : 0.06),
                            radius: bowlGlow ? 16 : 6,
                            y: bowlGlow ? 6 : 3
                        )
                        .animation(.easeOut(duration: 0.18), value: bowlStrike)
                        .animation(
                            isRunning
                            ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.25),
                            value: bowlGlow
                        )

                    Text(secondsRemaining.clockString)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(isRunning ? "Tap bowl to end session" : "Tap bowl to begin session")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 20)
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func stopSession() {
        stopBell()
        invalidateTimer()
        isRunning = false
        bowlGlow = false
        endDate = nil
        sessionStartDate = nil
        syncDurationIfIdle()
    }

    private func resetSession() {
        stopBell()
        invalidateTimer()
        isRunning = false
        bowlGlow = false
        endDate = nil
        sessionStartDate = nil
        totalSeconds = resolvedMinutes * 60
        secondsRemaining = totalSeconds
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

        totalCompletedSeconds += totalSeconds

        if playEndBell {
            ringBell()
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
        bellPlayer?.stop()
        bellPlayer?.currentTime = 0
        bellPlayer = nil
    }
    private func ringBell() {
        if let url = Bundle.main.url(forResource: "singing-bowl", withExtension: "m4a") {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)

                bellPlayer = try AVAudioPlayer(contentsOf: url)
                bellPlayer?.prepareToPlay()
                bellPlayer?.play()
                return
            } catch {
            }
        }

        AudioServicesPlaySystemSound(1104)
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
