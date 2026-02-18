import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
    @EnvironmentObject private var redactionDictionary: RedactionDictionary

    // Local model manager (singleton)
    @ObservedObject private var localModel = LocalModelManager.shared

    // Redaction entry
    @State private var newToken: String = ""
    @FocusState private var tokenFieldFocused: Bool

    // File import for .gguf
    @State private var showImporter: Bool = false
    @State private var importError: String? = nil
    @State private var dailyNudgeEnabled: Bool = UserDefaults.standard.bool(forKey: "daily_nudge_enabled")

    var body: some View {
        Form {
            // Processing (model picker)
            Section {
                Picker(SettingsCopy.providerLabel, selection: $providerSettings.choice) {
                    ForEach(ContemplationProviderSettings.Choice.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }

                if let foot = providerFootnote {
                    Text(foot)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(SettingsCopy.processingHeader)
            } footer: {
                Text(SettingsCopy.processingFootnote)
            }

            // Local model manager (moved directly under model picker)
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localModel.modelNameForUI)
                        .font(.headline)

                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if localModel.existsForUI {
                        Text("File: \(localModel.expectedFileNameForUI)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if localModel.fileSizeBytesForUI > 0 {
                            Text("Size: \(formatBytes(localModel.fileSizeBytesForUI))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Expected file: \(localModel.expectedFileNameForUI)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if case .downloading(let p) = localModel.state {
                    if let p = p {
                        ProgressView(value: p)
                    } else {
                        ProgressView()
                    }
                }

                HStack {
                    switch localModel.state {
                    case .notInstalled, .failed:
                        Button(SettingsCopy.localModelDownload) { localModel.startDownload() }
                        Button(SettingsCopy.localModelImport) { showImporter = true }

                    case .downloading:
                        Button("Cancel download") { localModel.cancelDownload() }
                            .tint(.orange)

                    case .ready:
                        Button(SettingsCopy.localModelDelete, role: .destructive) { localModel.deleteModel() }
                        Button("Re-download") {
                            localModel.deleteModel()
                            localModel.startDownload()
                        }
                    }
                }

                Text(SettingsCopy.localModelImportHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(SettingsCopy.localModelHeader)
            } footer: {
                Text(SettingsCopy.localModelStoredOnDeviceOnly)
            }

            // Privacy / Cloud Tap (keep toggle here; link to page without another toggle)
            Section {
                Toggle("Enable Cloud Tap", isOn: $cloudTap.isEnabled)

                NavigationLink(SettingsCopy.privacyLinkTitle) {
                    PrivacyView()
                }
            } header: {
                Text(SettingsCopy.privacyHeader)
            } footer: {
                Text(SettingsCopy.privacyFootnote)
            }

            // Redaction dictionary
            Section {
                if redactionDictionary.tokens.isEmpty {
                    Text(SettingsCopy.redactionEmpty)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(redactionDictionary.tokens, id: \.self) { token in
                        Text(token)
                            .textSelection(.enabled)
                    }
                    .onDelete { offsets in
                        redactionDictionary.remove(at: offsets)
                    }
                }

                HStack {
                    TextField(SettingsCopy.redactionAddPlaceholder, text: $newToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .focused($tokenFieldFocused)
                        .onSubmit { addToken() }

                    Button(SettingsCopy.redactionAddButton) { addToken() }
                        .disabled(newToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text(SettingsCopy.redactionHeader)
            }

            Section {
                Button(role: .destructive) {
                    redactionDictionary.wipe()
                } label: {
                    Text(SettingsCopy.redactionRemoveAll)
                }
            }
            Section {
                Toggle("Daily check-in reminder", isOn: $dailyNudgeEnabled)
                    .onChange(of: dailyNudgeEnabled) {
                        let isOn = dailyNudgeEnabled
                        UserDefaults.standard.set(isOn, forKey: "daily_nudge_enabled")

                        Task {
                            if isOn {
                                let ok = await NotificationManager.shared.requestPermissionIfNeeded()
                                if ok {
                                    await NotificationManager.shared.scheduleDaily(
                                        hour: 18,
                                        minute: 15,
                                        title: "Clarity",
                                        body: "One small step today - Reflect, View, or Practice."
                                    )
                                } else {
                                    NotificationManager.shared.openSystemSettings()
                                    dailyNudgeEnabled = false
                                    UserDefaults.standard.set(false, forKey: "daily_nudge_enabled")
                                }
                            } else {
                                await NotificationManager.shared.cancelDaily()
                            }
                        }
                    }



                Button("Notification Settings") {
                    NotificationManager.shared.openSystemSettings()
                }
                .font(.footnote)
            } header: {
                Text("Reminders")
            } footer: {
                Text("You can also turn this off in iOS Settings → Notifications → Clarity.")
            }

            // Transparency
            Section {
                Toggle(SettingsCopy.showLaneBadgesTitle, isOn: $cloudTap.showLaneBadges)

                Text(SettingsCopy.showLaneBadgesFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(SettingsCopy.transparencyHeader)
            }

            // Safety
            Section {
                HStack {
                    Text(SettingsCopy.drivingTitle)
                    Spacer()
                    Text(SettingsCopy.drivingValue)
                        .foregroundStyle(.secondary)
                }

                Text(SettingsCopy.drivingFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(SettingsCopy.safetyHeader)
            }

            // About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle(SettingsCopy.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear { localModel.refreshStatePublic() }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType(filenameExtension: "gguf") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        try localModel.importModel(from: url)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert(SettingsCopy.importFailedTitle, isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(SettingsCopy.ok, role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Helpers

    private var providerFootnote: String? {
        switch providerSettings.choice {
        case .deviceTapApple: return SettingsCopy.appleProviderFootnote
        case .deviceTapLlama: return SettingsCopy.llamaProviderFootnote
        case .auto, .cloudTap: return nil
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    private var statusText: String {
        switch localModel.state {
        case .notInstalled:
            return SettingsCopy.localModelNotInstalled
        case .downloading(let p):
            if let p = p { return "\(SettingsCopy.localModelDownloading) \(Int(p * 100))%" }
            return SettingsCopy.localModelDownloading
        case .ready:
            return SettingsCopy.localModelInstalled
        case .failed(let msg):
            return "Failed: \(msg)"
        }
    }

    private func addToken() {
        let t = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        redactionDictionary.add(t)
        newToken = ""
        tokenFieldFocused = false
    }

    private func formatBytes(_ n: Int64) -> String {
        let mb = Double(n) / (1024.0 * 1024.0)
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024.0) }
        return String(format: "%.0f MB", mb)
    }
}

enum SettingsCopy {

    // MARK: - Navigation
    static let title = "Settings"

    // MARK: - Processing
    static let processingHeader = "Processing"
    static let providerLabel = "LLM model"

    // One short sentence. Avoid dense explanations in primary Settings rows.
    static let processingFootnote =
    "Choose where responses are generated. On-device stays on this iPhone. Cloud Tap sends selected text to the cloud when you choose it."

    static let appleProviderFootnote =
    "Uses Apple’s on-device model (requires iOS 26+ and an Apple Intelligence-capable device)."

    static let llamaProviderFootnote =
    "Runs locally using a downloaded model."

    // MARK: - Local model
    static let localModelHeader = "Local model"
    static let localModelStoredOnDeviceOnly =
    "Stored on this device only."

    static let localModelStatus = "Status"
    static let localModelInstalled = "Installed"
    static let localModelNotInstalled = "Not installed"
    static let localModelDownloading = "Downloading…"

    static let localModelDownload = "Download model"
    static let localModelImport = "Import model…"
    static let localModelDelete = "Delete model"
    static let localModelRefresh = "Refresh status"
    static let localModelAdvanced = "Advanced"

    static let localModelImportHint =
    "Choose a .gguf file from Files. Clarity will copy it into Application Support."

    // MARK: - Redaction
    static let redactionHeader = "Redaction"
    static let redactionEmpty = "No redacted terms yet."
    static let redactionAddPlaceholder = "Add a name or term to always redact"
    static let redactionAddButton = "Add"
    static let redactionRemoveAll = "Remove all redaction terms"
    static let redactionConfirmTitle = "Remove all redaction terms?"
    static let redactionConfirmMessage =
    "This clears your redaction list. You can add terms again at any time."
    static let redactionConfirmRemoveAll = "Remove all"
    static let redactionConfirmCancel = "Cancel"

    // MARK: - Privacy
    static let privacyHeader = "Privacy"
    static let privacyLinkTitle = "Privacy / Cloud Tap"

    // Keep this extremely clear for reviewers:
    // - what stays local
    // - what leaves device
    // - that it’s user-initiated
    static let privacyFootnote =
    "Audio and raw transcripts stay on this iPhone. If you choose Cloud Tap, only the selected (redacted) text is sent to generate a response."

    // MARK: - Transparency
    static let transparencyHeader = "Transparency"
    static let showLaneBadgesTitle = "Show lane badges"
    static let showLaneBadgesFootnote = "Label outputs as Local / On-device / Cloud Tap."

    // MARK: - Safety
    static let safetyHeader = "Safety"
    static let drivingTitle = "Driving / CarPlay"
    static let drivingValue = ""
    static let drivingFootnote = "Hands free audio capture playback."

    // MARK: - Errors
    static let importFailedTitle = "Couldn’t import model"
    static let ok = "OK"
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(CloudTapSettings())
            .environmentObject(ContemplationProviderSettings())
            .environmentObject(RedactionDictionary())
            .environmentObject(CapsuleStore())
    }
}
