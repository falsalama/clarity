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

    // Chat composer state
    @State private var chatInput: String = ""
    @State private var isSendingChat: Bool = false
    @FocusState private var isChatFocused: Bool

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

    // Talk composer visibility gate: becomes true after first assistant reply or a continuation id exists
    private var isTalkActive: Bool {
        guard let t = turn else { return false }
        if let id = t.talkLastResponseID, !id.isEmpty { return true }
        let thread = loadTalkThread(from: t)
        return thread.contains(where: { $0.role == .assistant })
    }

    // Strict “show talk section” gate: only after an assistant message exists
    private var hasTalkContent: Bool {
        guard let t = turn else { return false }
        let thread = loadTalkThread(from: t)
        return thread.contains(where: { $0.role == .assistant })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                playbackSection
                Divider()
                transcriptSection

                // Outputs section only when there’s content
                if hasAnyOutputs {
                    Divider()
                    outputsSection
                }

                // Talk-it-through section only after an assistant response exists
                if hasTalkContent {
                    Divider()
                    talkSection
                }

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
            if isSendingCloud || isSendingChat {
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.08))
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        ProgressView()
                        Text(isSendingChat ? "Sending message…" : "Sending…")
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
        .animation(.easeOut(duration: 0.15), value: isSendingChat)
        .allowsHitTesting(!(isSendingCloud || isSendingChat))
        .onChange(of: isTalkActive) { _, becameActive in
            if becameActive {
                // Auto-focus the composer when it first becomes visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isChatFocused = true
                }
            }
        }
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

            switch pendingTool {
            case .reflect, .options, .questions, .clarityView:
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
                    t.reflectText = resp.text
                    t.reflectPromptVersion = resp.prompt_version
                    t.reflectUpdatedAt = Date()
                case .options:
                    resp = try await service.options(req)
                    t.optionsText = resp.text
                    t.optionsPromptVersion = resp.prompt_version
                    t.optionsUpdatedAt = Date()
                case .questions:
                    resp = try await service.questions(req)
                    t.questionsText = resp.text
                    t.questionsPromptVersion = resp.prompt_version
                    t.questionsUpdatedAt = Date()
                case .clarityView:
                    resp = try await service.clarityView(req)
                    t.clarityViewText = resp.text
                    t.clarityViewPromptVersion = resp.prompt_version
                    t.clarityViewUpdatedAt = Date()
                default:
                    fatalError("Unexpected tool branch")
                }

                // Legacy mirror
                t.reflectionText = (t.reflectText ?? t.optionsText ?? t.questionsText ?? t.clarityViewText) ?? ""

            case .talkItThrough:
                // This path is now handled by the chat composer; keep here as a fallback single-shot send.
                let talkReq = CloudTapTalkRequest(
                    text: redactedText,
                    recordedAt: t.recordedAt.ISO8601Format(),
                    client: "ios",
                    appVersion: appVersion,
                    previous_response_id: t.talkLastResponseID,
                    capsule: snapshot
                )

                let talkResp: CloudTapTalkResponse = try await service.talkItThrough(talkReq)

                var thread = loadTalkThread(from: t)
                thread.append(TalkMessage(role: .user, text: redactedText))
                thread.append(TalkMessage(role: .assistant, text: talkResp.text))
                saveTalkThread(thread, into: t)

                t.talkLastResponseID = talkResp.response_id
                t.talkPromptVersion = talkResp.prompt_version
                t.talkUpdatedAt = Date()

                t.reflectionText = talkResp.text
            }

            try modelContext.save()
        } catch {
            cloudSendError = String(describing: error)
        }
    }

    private func capsuleSnapshotOrNil() -> CloudTapCapsuleSnapshot? {
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

    // MARK: - Talk thread helpers

    private func loadTalkThread(from t: TurnEntity) -> [TalkMessage] {
        let data = t.talkThreadJSON
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([TalkMessage].self, from: data)) ?? []
    }

    private func saveTalkThread(_ messages: [TalkMessage], into t: TurnEntity) {
        if let data = try? JSONEncoder().encode(messages) {
            t.talkThreadJSON = data
        }
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

            if hasContent(turn?.clarityViewText) {
                outputBlock(title: "Clarity - View", text: turn?.clarityViewText, prompt: turn?.clarityViewPromptVersion)
            }

            if hasContent(turn?.optionsText) {
                outputBlock(title: "Options", text: turn?.optionsText, prompt: turn?.optionsPromptVersion)
            }

            if hasContent(turn?.questionsText) {
                outputBlock(title: "Questions", text: turn?.questionsText, prompt: turn?.questionsPromptVersion)
            }
        }
    }

    // MARK: - Talk thread UI

    private var talkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Talk it through")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Thread list
            if let t = turn {
                let thread = loadTalkThread(from: t)
                if !thread.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(thread) { msg in
                            HStack {
                                if msg.role == .assistant {
                                    Spacer(minLength: 20)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(msg.role == .user ? "You" : "Clarity")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(msg.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(10)
                                .background(msg.role == .user ? Color.blue.opacity(0.08) : Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                if msg.role == .user {
                                    Spacer(minLength: 20)
                                }
                            }
                        }
                    }
                }
            }

            // Composer (only after first assistant response / active thread)
            if isTalkActive {
                HStack(spacing: 8) {
                    TextField("Type a message…", text: $chatInput, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .lineLimit(1...3)
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($isChatFocused)

                    Button(isSendingChat ? "Sending…" : "Send") {
                        Task { await sendChatMessage() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSendingChat || chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (turn == nil))
                }
            }

            if let id = turn?.talkLastResponseID, !id.isEmpty {
                Text("Thread active")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sendChatMessage() async {
        guard !isSendingChat else { return }
        guard let t = turn else { return }

        // Redact user-entered text before sending
        let input = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        let redacted = Redactor(tokens: dictionary.tokens).redact(input).redactedText
        guard !redacted.isEmpty else { return }

        isSendingChat = true
        defer { isSendingChat = false }

        let service = CloudTapService(
            baseURL: CloudTapConfig.baseURL,
            anonKey: CloudTapConfig.supabaseAnonKey
        )

        let appVersion =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0"

        let snapshot = capsuleSnapshotOrNil()

        // Optimistically append the user message locally
        var thread = loadTalkThread(from: t)
        let optimisticUser = TalkMessage(role: .user, text: redacted)
        thread.append(optimisticUser)
        saveTalkThread(thread, into: t)
        chatInput = ""

        do {
            let req = CloudTapTalkRequest(
                text: redacted,
                recordedAt: t.recordedAt.ISO8601Format(),
                client: "ios",
                appVersion: appVersion,
                previous_response_id: t.talkLastResponseID,
                capsule: snapshot
            )

            let resp: CloudTapTalkResponse = try await service.talkItThrough(req)

            // Append assistant response and update continuation
            thread.append(TalkMessage(role: .assistant, text: resp.text))
            saveTalkThread(thread, into: t)

            t.talkLastResponseID = resp.response_id
            t.talkPromptVersion = resp.prompt_version
            t.talkUpdatedAt = Date()

            // Optional mirror for quick visibility
            t.reflectionText = resp.text

            try modelContext.save()
        } catch {
            // Roll back optimistic user append on failure
            var rolled = loadTalkThread(from: t)
            if let idx = rolled.lastIndex(where: { $0.id == optimisticUser.id }) {
                rolled.remove(at: idx)
                saveTalkThread(rolled, into: t)
            }
            cloudSendError = String(describing: error)
        }
    }

    private func hasContent(_ s: String?) -> Bool {
        guard let s else { return false }
        return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnyOutputs: Bool {
        hasContent(turn?.reflectText)
        || hasContent(turn?.clarityViewText)
        || hasContent(turn?.optionsText)
        || hasContent(turn?.questionsText)
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
            toolButton(title: toolTitle(.clarityView), tool: .clarityView, enabled: enabled)
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
        case .clarityView:
            return (t.clarityViewText?.isEmpty == false) ? "Re-run Clarity - View" : "Clarity - View"
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
    case clarityView = "Clarity - View"
    case options = "Options"
    case questions = "Questions"
    case talkItThrough = "Talk it through"
    var id: String { rawValue }
}

