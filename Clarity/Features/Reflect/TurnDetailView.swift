import SwiftUI
import SwiftData

struct TurnDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
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

    // Scroll control
    @State private var scrollProxy: ScrollViewProxy? = nil
    private let outputsBottomID = "outputsBottom"

    init(turnID: UUID) {
        self.turnID = turnID
        _matches = Query(filter: #Predicate<TurnEntity> { $0.id == turnID })
    }

    private var turn: TurnEntity? { matches.first }

    // MARK: - Audio

    private var isAudioMissing: Bool {
        // Missing means: there is a stored reference, but we cannot resolve it to a real file.
        guard let stored = turn?.audioPath, !stored.isEmpty else { return false }
        return FileStore.existingAudioURL(from: stored) == nil
    }

    // MARK: - Talk gating

    private var isTalkActive: Bool {
        guard let t = turn else { return false }
        if let id = t.talkLastResponseID, !id.isEmpty { return true }
        return loadTalkThread(from: t).contains { $0.role == .assistant }
    }

    private var hasTalkContent: Bool {
        guard let t = turn else { return false }
        return loadTalkThread(from: t).contains { $0.role == .assistant }
    }

    // MARK: - WAL badge (ONLY signal)

    private var hasWAL: Bool {
        guard let t = turn else { return false }

        // Robust “is it non-empty” check without decoding.
        // Default is "{}" in your model.
        let s = String(data: t.walJSON, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return !s.isEmpty && s != "{}" && s != "null"
    }

    // MARK: - Derived

    private var hasAnyOutputs: Bool {
        hasContent(turn?.reflectText)
        || hasContent(turn?.perspectiveText)
        || hasContent(turn?.optionsText)
        || hasContent(turn?.questionsText)
    }

    private var isToolsEnabled: Bool {
        let isReady = (turn?.stateRaw == "ready")
        let hasText = !transcriptForCloudPayload(from: turn).isEmpty
        return isReady && hasText
    }

    // MARK: - View

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
                    .padding()
                    .id("scrollRoot")
            }
            .onAppear {
                self.scrollProxy = proxy
                if let t = turn, let updated = FileStore.normalisedStoredAudioPath(from: t.audioPath) {
                    t.audioPath = updated
                    try? modelContext.save()
                }
                player.load(storedAudioPath: turn?.audioPath)
            }
            .onChange(of: turn?.audioPath) { _, _ in
                player.load(storedAudioPath: turn?.audioPath)
            }

            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)

            .onDisappear { player.stop() }
            .sheet(item: $sheetRoute) { route in
                switch route {
                case .cloudTapOff:
                    CloudTapOffSheet()
                case .missingCapture:
                    MissingCaptureSheet()
                }
            }
            .alert("Send to Cloud Tap?", isPresented: $showCloudConfirm) {
                Button("Cancel", role: .cancel) {}

                Button(isSendingCloud ? "Sending…" : "Send") {
                    Task { await sendCloudTapRequest() }
                }
                .disabled(isSendingCloud || transcriptForCloudPayload(from: turn).isEmpty)
            } message: {
                Text("Send redacted text to generate \(pendingTool.rawValue). Audio and raw transcript stay on this device.")
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
                    sendingOverlay
                }
            }
            .allowsHitTesting(!(isSendingCloud || isSendingChat))
            .onChange(of: isTalkActive) { _, becameActive in
                if becameActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isChatFocused = true
                    }
                }
            }
            // Auto-scroll when any output changes to keep it in view
            .onChange(of: turn?.reflectText) { _, _ in scrollOutputsToBottom() }
            .onChange(of: turn?.perspectiveText) { _, _ in scrollOutputsToBottom() }
            .onChange(of: turn?.optionsText) { _, _ in scrollOutputsToBottom() }
            .onChange(of: turn?.questionsText) { _, _ in scrollOutputsToBottom() }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            playbackSection
            Divider()
            transcriptSection

            // WAL preview removed per design: show only the badge in header.

            Divider()
            actionsSection

            if hasAnyOutputs {
                Divider()
                outputsSection
                // Invisible anchor to scroll to
                Color.clear
                    .frame(height: 1)
                    .id(outputsBottomID)
            }

            if hasTalkContent {
                Divider()
                talkSection
            }
        }
    }

    private func scrollOutputsToBottom() {
        guard hasAnyOutputs else { return }
        guard let proxy = scrollProxy else { return }
        // Defer to next runloop to ensure layout updated
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(outputsBottomID, anchor: .bottom)
            }
        }
    }

    private var sendingOverlay: some View {
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

                if hasWAL {
                    LaneBadge(text: "WAL ready")
                }

                Spacer()
            }

            if let t = turn, t.stateRaw == "failed",
               let msg = t.errorDebugMessage, !msg.isEmpty {
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

            if !isAudioMissing, (turn?.audioPath?.isEmpty == false) {
                HStack(spacing: 12) {
                    Button {
                        if player.duration == 0 { player.load(storedAudioPath: turn?.audioPath) }
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
            } else if isAudioMissing {
                Text("Audio missing for this capture.")
                    .foregroundStyle(.secondary)
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

            if hasContent(turn?.perspectiveText) {
                outputBlock(title: "Perspective", text: turn?.perspectiveText, prompt: turn?.perspectivePromptVersion)
            }

            if hasContent(turn?.optionsText) {
                outputBlock(title: "Options", text: turn?.optionsText, prompt: turn?.optionsPromptVersion)
            }

            if hasContent(turn?.questionsText) {
                outputBlock(title: "Questions", text: turn?.questionsText, prompt: turn?.questionsPromptVersion)
            }
        }
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

    // MARK: - Talk

    private var talkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Talk it through")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let t = turn {
                let thread = loadTalkThread(from: t)
                if !thread.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(thread) { msg in
                            HStack {
                                if msg.role == .assistant { Spacer(minLength: 20) }

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

                                if msg.role == .user { Spacer(minLength: 20) }
                            }
                        }
                    }
                }
            }

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

        let snapshot = capsuleSnapshotOrNil(for: pendingTool)

        // Optimistically append user message locally
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

            thread.append(TalkMessage(role: .assistant, text: resp.text))
            saveTalkThread(thread, into: t)

            t.talkLastResponseID = resp.response_id
            t.talkPromptVersion = resp.prompt_version
            t.talkUpdatedAt = Date()

            // Optional mirror
            t.reflectionText = resp.text

            try modelContext.save()
        } catch {
            // Roll back optimistic append
            var rolled = loadTalkThread(from: t)
            if let idx = rolled.lastIndex(where: { $0.id == optimisticUser.id }) {
                rolled.remove(at: idx)
                saveTalkThread(rolled, into: t)
            }
            cloudSendError = String(describing: error)
        }
    }

    // MARK: - Tools

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tools")
                .font(.footnote)
                .foregroundStyle(.secondary)

            toolButton(title: toolTitle(.reflect), tool: .reflect, enabled: isToolsEnabled)
            toolButton(title: toolTitle(.perspective), tool: .perspective, enabled: isToolsEnabled)
            toolButton(title: toolTitle(.options), tool: .options, enabled: isToolsEnabled)
            toolButton(title: toolTitle(.questions), tool: .questions, enabled: isToolsEnabled)
            toolButton(title: "Talk it through", tool: .talkItThrough, enabled: isToolsEnabled)

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
        case .perspective:
            return (t.perspectiveText?.isEmpty == false) ? "Re-run perspective" : "Perspective"
        case .options:
            return (t.optionsText?.isEmpty == false) ? "Re-run Options" : "Options"
        case .questions:
            return (t.questionsText?.isEmpty == false) ? "Re-run Questions" : "Questions"
        case .talkItThrough:
            return "Talk it through"
        }
    }

    private func toolTint(_ tool: CloudTool) -> Color {
        switch tool {

        // White – Air / Clarity
        case .reflect:
            return Color(red: 0.55, green: 0.42, blue: 0.18)

        // Blue – Space / Vastness
        case .perspective:
            return Color(red: 0.08, green: 0.18, blue: 0.42)

        // Green – Water / Movement
        case .options:
            return Color(red: 0.10, green: 0.48, blue: 0.32)

        // Red – Fire / Cutting
        case .questions:
            return Color(red: 0.58, green: 0.10, blue: 0.14)

        // Yellow – Earth / Grounding
        case .talkItThrough:
            return Color(red: 0.78, green: 0.62, blue: 0.12)
        }
    }



    private func toolButton(title: String, tool: CloudTool, enabled: Bool) -> some View {
        Button { requestTool(tool) } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(toolTint(tool))
        .disabled(!enabled)
    }

    private func requestTool(_ tool: CloudTool) {
        pendingTool = tool

        guard turn != nil else {
            sheetRoute = .missingCapture
            return
        }

        if shouldUseCloudTap(for: tool) {
            guard cloudTap.isEnabled else {
                sheetRoute = .cloudTapOff
                return
            }
            showCloudConfirm = true
        } else {
            Task { await sendDeviceTapRequest() }
        }
    }

    private func shouldUseCloudTap(for tool: CloudTool) -> Bool {
        // Talk-it-through remains cloud-only for now.
        if tool == .talkItThrough { return true }
        switch providerSettings.choice {
        case .cloudTap:
            return true
        case .auto:
            // Until Device Tap is wired, keep Auto on Cloud Tap.
            return true
        case .deviceTapApple, .deviceTapLlama:
            return false
        }
    }

    private func sendDeviceTapRequest() async {
        guard let t = turn else { return }
        let redactedText = transcriptForCloudPayload(from: t)
        guard !redactedText.isEmpty else { return }

        isSendingCloud = true
        defer { isSendingCloud = false }

        let appVersion =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0"

        let snapshot = capsuleSnapshotOrNil(for: .talkItThrough)

        let mode: ContemplationMode
        switch pendingTool {
        case .reflect: mode = .reflect
        case .perspective: mode = .perspective
        case .options: mode = .options
        case .questions: mode = .questions
        case .talkItThrough: mode = .talkItThrough
        }

        let request = ContemplationRequest(
            mode: mode,
            text: redactedText,
            recordedAtISO: t.recordedAt.ISO8601Format(),
            appVersion: appVersion,
            capsule: snapshot,
            previousResponseID: t.talkLastResponseID
        )

        do {
            let service = ContemplationService(cloudTap: cloudTap, providerSettings: providerSettings)
            let resp = try await service.generate(request)

            // Save into the same fields as Cloud Tap so the UI stays the same.
            switch pendingTool {
            case .reflect:
                t.reflectText = resp.text
                t.reflectPromptVersion = resp.promptVersion
                t.reflectUpdatedAt = Date()
            case .options:
                t.optionsText = resp.text
                t.optionsPromptVersion = resp.promptVersion
                t.optionsUpdatedAt = Date()
            case .questions:
                t.questionsText = resp.text
                t.questionsPromptVersion = resp.promptVersion
                t.questionsUpdatedAt = Date()
            case .perspective:
                t.perspectiveText = resp.text
                t.perspectivePromptVersion = resp.promptVersion
                t.perspectiveUpdatedAt = Date()
            case .talkItThrough:
                t.reflectionText = resp.text
            }

            t.reflectionText = (t.reflectText ?? t.optionsText ?? t.questionsText ?? t.perspectiveText) ?? ""
            try modelContext.save()

            // Scroll to show the latest outputs
            scrollOutputsToBottom()
        } catch {
            cloudSendError = String(describing: error)
        }
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

            let snapshot = capsuleSnapshotOrNil(for: pendingTool)

            switch pendingTool {
            case .reflect, .options, .questions, .perspective:
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
                case .perspective:
                    resp = try await service.perspective(req)
                    t.perspectiveText = resp.text
                    t.perspectivePromptVersion = resp.prompt_version
                    t.perspectiveUpdatedAt = Date()
                default:
                    fatalError("Unexpected tool branch")
                }

                // Legacy mirror
                t.reflectionText = (t.reflectText ?? t.optionsText ?? t.questionsText ?? t.perspectiveText) ?? ""

            case .talkItThrough:
                // Leave this button as a single-shot fallback; the real path is the composer.
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

            // Scroll to show the latest outputs
            scrollOutputsToBottom()
        } catch {
            cloudSendError = String(describing: error)
        }
    }

    private func capsuleSnapshotOrNil(for tool: CloudTool? = nil) -> CloudTapCapsuleSnapshot? {
        let c = capsuleStore.capsule
        let p = c.preferences

        let hasTyped =
            (p.outputStyle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            || (p.optionsBeforeQuestions != nil)
            || (p.noTherapyFraming != nil)
            || (p.noPersona != nil)

        let hasExtras = !p.extras.isEmpty

        // Decide capsule mode based on tool (talk vs everything else)
        let mode: CloudTapCapsuleMode = (tool == .talkItThrough) ? .talk : .reflect

        // Learned cues count only when learningEnabled is true
        let learned = c.cloudTapLearnedCuesPayload(max: 12, mode: mode)
        let hasLearned = (learned?.isEmpty == false)

        guard hasTyped || hasExtras || hasLearned else { return nil }
        return CloudTapCapsuleSnapshot.fromCapsule(c, mode: mode)
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

    private func hasContent(_ s: String?) -> Bool {
        guard let s else { return false }
        return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func mmss(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
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
        case "queued": return "Processing"
        case "recording": return "recording"
        case "processing", "stopping": return "Processing"
        case "transcribing", "transcribedRaw": return "Transcribing"
        case "redacting": return "Redacting"
        case "interrupted": return "Interrupted"
        case "failed": return "Failed"
        case "captured": return "Processing"
        case "ready", .none: return nil
        default: return "Processing"
        }
    }
}

// MARK: - Cloud Tap gating

private enum CloudTool: String, CaseIterable, Identifiable {
    case reflect = "Reflect"
    case perspective = "Perspective"
    case options = "Options"
    case questions = "Questions"
    case talkItThrough = "Talk it through"
    var id: String { rawValue }
}
