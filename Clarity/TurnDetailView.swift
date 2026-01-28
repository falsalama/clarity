import SwiftUI
import SwiftData

struct TurnDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var capsuleStore: CapsuleStore

    let turnID: UUID

    @State private var showRawLocal: Bool = false
    @State private var sheetRoute: SheetRoute? = nil
    @State private var pendingTool: CloudTool = .reflect

    @State private var showCloudConfirm: Bool = false
    @State private var isSendingCloud: Bool = false
    @State private var cloudSendError: String? = nil

    @StateObject private var player = LocalAudioPlayer()

    @Query private var matches: [TurnEntity]

    init(turnID: UUID) {
        self.turnID = turnID
        _matches = Query(filter: #Predicate<TurnEntity> { $0.id == turnID })
    }

    private var turn: TurnEntity? { matches.first }

    private var audioURL: URL? {
        guard let path = turn?.audioPath, !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                playbackSection
                Divider()
                transcriptSection
                Divider()
                outputsSection
                Divider()
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Capture")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            if let url = audioURL { player.load(url: url) }
        }
        .onChange(of: turn?.audioPath) { _, _ in
            if let url = audioURL { player.load(url: url) }
        }
        .onDisappear {
            player.stop()
        }
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .cloudTapOff:
                CloudTapOffSheet()
            case .missingCapture:
                MissingCaptureSheet()
            }
        }
        .alert(cloudConfirmTitle, isPresented: $showCloudConfirm) {
            Button("Cancel", role: .cancel) {}

            Button(isSendingCloud ? "Sending…" : "Send") {
                Task { await sendCloudTapRequest() }
            }
            .disabled(isSendingCloud || transcriptForCloudPayload(from: turn).isEmpty)
        } message: {
            Text(cloudConfirmMessage)
        }
        .alert("Couldn't Send", isPresented: Binding(
            get: { cloudSendError != nil },
            set: { if !$0 { cloudSendError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cloudSendError ?? "")
        }
        .overlay {
            if isSendingCloud {
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.08))
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Sending…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isSendingCloud)
        .allowsHitTesting(!isSendingCloud)
    }

    private var cloudConfirmTitle: String { "Send to Cloud Tap?" }

    private var cloudConfirmMessage: String {
        "Send redacted text to generate \(pendingTool.rawValue). Audio and raw transcript stay on this device."
    }

    private func sendCloudTapRequest() async {
        guard !isSendingCloud else { return }
        guard let t = turn else {
            cloudSendError = "Capture unavailable."
            return
        }

        let redactedText = transcriptForCloudPayload(from: t)
        guard !redactedText.isEmpty else { return }

        isSendingCloud = true
        defer { isSendingCloud = false }

        do {
            let service = CloudTapService(
                baseURL: CloudTapConfig.baseURL,
                anonKey: CloudTapConfig.supabaseAnonKey
            )

            let appVersion =
                Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                ?? "0"

            let snapshot = capsuleSnapshotOrNil()

#if DEBUG
            if let snapshot {
                print("CloudTap capsule snapshot keys:", snapshot.preferences.keys.sorted())
            } else {
                print("CloudTap capsule snapshot: nil (empty capsule)")
            }
#endif

            let req = CloudTapReflectRequest(
                text: redactedText,
                recordedAt: t.recordedAt.ISO8601Format(),
                client: "ios",
                appVersion: appVersion,
                capsule: snapshot
            )

            let resp: CloudTapReflectResponse
            switch pendingTool {
            case .reflect:
                resp = try await service.reflect(req)
            case .options:
                resp = try await service.options(req)
            case .questions:
                resp = try await service.questions(req)
            case .talkItThrough:
                // For now, treat as single-shot until you wire multi-turn UI.
                resp = try await service.options(req)
            }

            switch pendingTool {
            case .reflect:
                t.reflectText = resp.text
                t.reflectPromptVersion = resp.prompt_version
                t.reflectUpdatedAt = Date()
            case .options:
                t.optionsText = resp.text
                t.optionsPromptVersion = resp.prompt_version
                t.optionsUpdatedAt = Date()
            case .questions:
                t.questionsText = resp.text
                t.questionsPromptVersion = resp.prompt_version
                t.questionsUpdatedAt = Date()
            case .talkItThrough:
                break
            }

            // Legacy field kept for now
            t.reflectionText = resp.text

            try modelContext.save()
        } catch {
            cloudSendError = String(describing: error)
        }
    }

    private func capsuleSnapshotOrNil() -> CloudTapCapsuleSnapshot? {
        // Don’t send capsule if it’s empty (makes server-side verification easy).
        let c = capsuleStore.capsule
        let p = c.preferences

        let hasTyped =
            (p.outputStyle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            || (p.optionsBeforeQuestions != nil)
            || (p.noTherapyFraming != nil)
            || (p.noPersona != nil)

        let hasExtras = !p.extras.isEmpty

        guard hasTyped || hasExtras else { return nil }
        return CloudTapCapsuleSnapshot.fromCapsule(c)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                titleField
                Spacer()
                StatusPill(stateRaw: turn?.stateRaw)
            }

            Text(turnDateText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                LaneBadge(text: contextLabel(captureContextRaw: turn?.captureContextRaw))

                if cloudTap.isEnabled {
                    LaneBadge(text: "Cloud Tap armed")
                }

                Spacer()
            }

            if let t = turn, t.stateRaw == "failed", let msg = t.errorDebugMessage, !msg.isEmpty {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var titleField: some View {
        if let t = turn {
            TextField("Untitled", text: Binding(
                get: { displayTitle(for: t) },
                set: { newValue in
                    t.title = newValue
                    try? modelContext.save()
                }
            ))
            .font(.headline)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
        } else {
            Text("Not found")
                .font(.headline)
        }
    }

    private func displayTitle(for t: TurnEntity) -> String {
        let manual = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty { return t.title }

        if let auto = autoTitleFromTranscript(for: t), !auto.isEmpty { return auto }
        return ""
    }

    private func autoTitleFromTranscript(for t: TurnEntity) -> String? {
        let source: String
        if !t.transcriptRedactedActive.isEmpty {
            source = t.transcriptRedactedActive
        } else if let raw = t.transcriptRaw, !raw.isEmpty {
            source = raw
        } else {
            return nil
        }

        let cleaned = source
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let words = cleaned.split(separator: " ").prefix(7).map(String.init)
        let title = words.joined(separator: " ")
        return String(title.prefix(56))
    }

    private var turnDateText: String {
        guard let d = turn?.recordedAt else { return "—" }
        return d.formatted(date: .abbreviated, time: .shortened)
    }

    private func contextLabel(captureContextRaw: String?) -> String {
        switch captureContextRaw {
        case "carplay": return "Drive"
        case "handsfree": return "Hands-free"
        case "intent": return "Intent"
        case "handheld": return "Handheld"
        default: return "Capture"
        }
    }

    // MARK: - Playback

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Audio")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let url = audioURL {
                HStack(spacing: 12) {
                    Button {
                        if player.duration == 0 { player.load(url: url) }
                        player.toggle()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { player.seek(to: $0) }
                            ),
                            in: 0...max(player.duration, 0.01)
                        )

                        HStack {
                            Text(mmss(player.currentTime))
                            Spacer()
                            Text(mmss(player.duration))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if let e = player.lastError, !e.isEmpty {
                    Text(e)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No audio file found.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Transcript")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Toggle("Show raw transcript (local only)", isOn: $showRawLocal)
                .font(.footnote)

            if let display = transcriptForDisplay(), !display.isEmpty {
                Text(display)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                Text(transcriptPlaceholder(for: turn?.stateRaw))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func transcriptForDisplay() -> String? {
        guard let t = turn else { return nil }

        if showRawLocal {
            return t.transcriptRaw
        }

        if !t.transcriptRedactedActive.isEmpty {
            return t.transcriptRedactedActive
        }

        guard let raw = t.transcriptRaw, !raw.isEmpty else { return nil }
        return Redactor(tokens: dictionary.tokens).redact(raw).redactedText
    }

    private func transcriptForCloudPayload(from t: TurnEntity?) -> String {
        guard let t else { return "" }
        if !t.transcriptRedactedActive.isEmpty { return t.transcriptRedactedActive }
        guard let raw = t.transcriptRaw, !raw.isEmpty else { return "" }
        return Redactor(tokens: dictionary.tokens).redact(raw).redactedText
    }

    // MARK: - Outputs

    private var outputsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Outputs")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if hasContent(turn?.reflectText) {
                outputBlock(title: "Reflect", text: turn?.reflectText, prompt: turn?.reflectPromptVersion)
            }

            if hasContent(turn?.optionsText) {
                outputBlock(title: "Options", text: turn?.optionsText, prompt: turn?.optionsPromptVersion)
            }

            if hasContent(turn?.questionsText) {
                outputBlock(title: "Questions", text: turn?.questionsText, prompt: turn?.questionsPromptVersion)
            }

            if !hasAnyOutputs {
                Text("No outputs yet. Use Tools below to generate Reflect, Options, or Questions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let id = turn?.talkLastResponseID, !id.isEmpty {
                Text("Talk it through thread active.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func hasContent(_ s: String?) -> Bool {
        guard let s else { return false }
        return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnyOutputs: Bool {
        hasContent(turn?.reflectText) || hasContent(turn?.optionsText) || hasContent(turn?.questionsText)
    }

    @ViewBuilder
    private func outputBlock(title: String, text: String?, prompt: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let p = prompt, !p.isEmpty {
                    Text(p)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let t = text, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(t)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Tools

    private var actionsSection: some View {
        let isReady = (turn?.stateRaw == "ready")
        let hasText = !transcriptForCloudPayload(from: turn).isEmpty
        let enabled = isReady && hasText

        return VStack(alignment: .leading, spacing: 10) {
            Text("Tools")
                .font(.footnote)
                .foregroundStyle(.secondary)

            toolButton(title: toolTitle(.reflect), tool: .reflect, enabled: enabled)
            toolButton(title: toolTitle(.options), tool: .options, enabled: enabled)
            toolButton(title: toolTitle(.questions), tool: .questions, enabled: enabled)
            toolButton(title: "Talk it through", tool: .talkItThrough, enabled: enabled)

            Text("Cloud actions are explicit and always require confirmation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toolTitle(_ tool: CloudTool) -> String {
        guard let t = turn else { return tool.rawValue }
        switch tool {
        case .reflect:
            return (t.reflectText?.isEmpty == false) ? "Re-run Reflect" : "Reflect"
        case .options:
            return (t.optionsText?.isEmpty == false) ? "Re-run Options" : "Options"
        case .questions:
            return (t.questionsText?.isEmpty == false) ? "Re-run Questions" : "Questions"
        case .talkItThrough:
            return "Talk it through"
        }
    }

    private func toolButton(title: String, tool: CloudTool, enabled: Bool) -> some View {
        Button(title) { requestCloudTool(tool) }
            .buttonStyle(.bordered)
            .disabled(!enabled)
    }

    private func requestCloudTool(_ tool: CloudTool) {
        pendingTool = tool

        guard turn != nil else {
            sheetRoute = .missingCapture
            return
        }

        guard cloudTap.isEnabled else {
            sheetRoute = .cloudTapOff
            return
        }

        showCloudConfirm = true
    }

    // MARK: - Placeholder

    private func transcriptPlaceholder(for stateRaw: String?) -> String {
        switch stateRaw {
        case "queued": return "Queued."
        case "recording": return "Recording…"
        case "captured": return "Captured."
        case "transcribing", "transcribedRaw": return "Transcribing…"
        case "redacting": return "Redacting…"
        case "ready": return "—"
        case "interrupted": return "Interrupted (audio still saved)."
        case "failed": return "Failed (audio still saved)."
        case .none: return "Not found."
        default: return "Processing…"
        }
    }
}

// MARK: - Sheet routing

private enum SheetRoute: String, Identifiable {
    case cloudTapOff
    case missingCapture
    var id: String { rawValue }
}

// MARK: - Local UI

private struct StatusPill: View {
    let stateRaw: String?

    var body: some View {
        if let label {
            Text(label)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(SwiftUI.Capsule())
                .foregroundStyle(.secondary)
                .accessibilityLabel(label)
        }
    }

    private var label: String? {
        switch stateRaw {
        case "queued": return "Queued"
        case "recording": return "Recording"
        case "transcribing", "transcribedRaw": return "Transcribing"
        case "redacting": return "Redacting"
        case "interrupted": return "Interrupted"
        case "failed": return "Failed"
        case "captured": return "Captured"
        case "ready", .none: return nil
        default: return nil
        }
    }
}

// MARK: - Cloud Tap gating

private enum CloudTool: String, CaseIterable, Identifiable {
    case reflect = "Reflect"
    case options = "Options"
    case questions = "Questions"
    case talkItThrough = "Talk it through"
    var id: String { rawValue }
}

private struct CloudTapOffSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Cloud Tap is off")
                        .font(.headline)
                    Text("This tool uses Cloud Tap. Nothing leaves this device unless you enable Cloud Tap and confirm each send.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    NavigationLink("Review Cloud Tap settings") {
                        PrivacyView()
                    }
                }

                Section {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle("Cloud Tap")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

private struct MissingCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Capture unavailable")
                        .font(.headline)
                    Text("This capture could not be loaded. Return to the timeline and try again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle("Capture")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

