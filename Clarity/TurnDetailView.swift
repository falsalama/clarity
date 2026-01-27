import SwiftUI
import SwiftData

struct TurnDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var dictionary: RedactionDictionary

    let turnID: UUID

    @State private var showRawLocal: Bool = false
    @State private var sheetRoute: SheetRoute? = nil
    @State private var pendingTool: CloudTool = .reflect

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
            case .confirmSend:
                ConfirmCloudTapSendSheet(
                    tool: pendingTool,
                    recordedAt: turn?.recordedAt,
                    redactedText: transcriptForCloudPayload(from: turn)
                )
            case .missingCapture:
                MissingCaptureSheet()
            }
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
                TurnLaneBadge(text: contextLabel(captureContextRaw: turn?.captureContextRaw))

                if cloudTap.isEnabled {
                    TurnLaneBadge(text: "Cloud Tap armed")
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

    // MARK: - Tools

    private var actionsSection: some View {
        let isReady = (turn?.stateRaw == "ready")
        let hasText = !transcriptForCloudPayload(from: turn).isEmpty
        let enabled = isReady && hasText

        return VStack(alignment: .leading, spacing: 10) {
            Text("Tools")
                .font(.footnote)
                .foregroundStyle(.secondary)

            toolButton("Reflect", tool: .reflect, enabled: enabled)
            toolButton("Options", tool: .options, enabled: enabled)
            toolButton("Questions", tool: .questions, enabled: enabled)
            toolButton("Talk it through", tool: .talkItThrough, enabled: enabled)

            Text("Cloud actions are explicit and always require confirmation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toolButton(_ title: String, tool: CloudTool, enabled: Bool) -> some View {
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

        sheetRoute = .confirmSend
    }

    // MARK: - Copy

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
    case confirmSend
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

private struct TurnLaneBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(SwiftUI.Capsule())
            .foregroundStyle(.secondary)
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

private struct ConfirmCloudTapSendSheet: View {
    @Environment(\.dismiss) private var dismiss

    let tool: CloudTool
    let recordedAt: Date?
    let redactedText: String

    @State private var isSending = false
    @State private var sendError: String? = nil
    @State private var responseText: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Confirm send")
                        .font(.headline)
                    Text("Redacted text only. Audio and raw transcript never leave this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Payload preview") {
                    LabeledContent("Tool") { Text(tool.rawValue) }
                    LabeledContent("Timestamp") { Text(timestampText) }
                    Text(redactedText.isEmpty ? "—" : redactedText)
                        .textSelection(.enabled)
                }

                Section {
                    Button(isSending ? "Sending…" : "Send") {
                        Task {
                            isSending = true
                            sendError = nil
                            responseText = nil
                            defer { isSending = false }

                            do {
                                let appVersion =
                                    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                                    ?? "0"

                                let req = CloudTapReflectRequest(
                                    text: redactedText,
                                    recordedAt: recordedAt?.ISO8601Format(),
                                    client: "ios",
                                    appVersion: appVersion
                                )

                                let res = try await CloudTapService().reflect(req)
                                responseText = String(describing: res)
                            } catch {
                                sendError = String(describing: error)
                            }
                        }
                    }
                    .disabled(isSending || redactedText.isEmpty)

                    if let sendError {
                        Text(sendError)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let responseText {
                        Text(responseText)
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle(tool.rawValue)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    private var timestampText: String {
        guard let recordedAt else { return "—" }
        return recordedAt.formatted(date: .abbreviated, time: .shortened)
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

