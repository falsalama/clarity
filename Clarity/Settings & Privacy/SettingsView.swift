import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var reflectStore: ClarityReflectStore
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
    @EnvironmentObject private var redactionDictionary: RedactionDictionary

    // Redaction entry
    @State private var newToken: String = ""
    @FocusState private var tokenFieldFocused: Bool

    @State private var dailyNudgeEnabled: Bool = UserDefaults.standard.bool(forKey: "daily_nudge_enabled")

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    ClarityReflectView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account")

                        Text(accountSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Generated Reflect responses require Clarity Reflect or Support Clarity.")
            }

            Section {
                Toggle("Daily check-in reminder", isOn: $dailyNudgeEnabled)
                    .onChange(of: dailyNudgeEnabled) {
                        let isOn = dailyNudgeEnabled
                        UserDefaults.standard.set(isOn, forKey: "daily_nudge_enabled")

                        Task {
                            if isOn {
                                let ok = await NotificationManager.shared.requestPermissionIfNeeded()
                                guard ok else {
                                    NotificationManager.shared.openSystemSettings()
                                    dailyNudgeEnabled = false
                                    UserDefaults.standard.set(false, forKey: "daily_nudge_enabled")
                                    return
                                }

                                // Confirm delivery immediately (normal UX, not debug).
                                await NotificationManager.shared.scheduleTestIn(
                                    seconds: 10,
                                    title: "Clarity",
                                    body: "Reminder is on."
                                )

                                // Daily repeating reminder.
                                await NotificationManager.shared.scheduleDaily(
                                    hour: 10,
                                    minute: 0
                                )
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

            // Processing
            if FeatureFlags.showModelProviderSettings {
                Section {
                    Picker(SettingsCopy.providerLabel, selection: $providerSettings.choice) {
                        ForEach(ContemplationProviderSettings.visibleChoices) { choice in
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
            }

            // Privacy / Cloud Tap
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
    }

    // MARK: - Helpers

    private var providerFootnote: String? {
        switch providerSettings.choice {
        case .deviceTapApple: return SettingsCopy.appleProviderFootnote
        case .auto, .cloudTap: return nil
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    private var accountSubtitle: String {
        if reflectStore.isSupportOnlyActive {
            return "Support Clarity active."
        }
        if reflectStore.hasPaidTier {
            return "Clarity Reflect active."
        }
        return "Core app free. Manage paid Reflect tools and support."
    }

    private func addToken() {
        let t = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        redactionDictionary.add(t)
        newToken = ""
        tokenFieldFocused = false
    }

}

enum SettingsCopy {

    // MARK: - Navigation
    static let title = "Settings"

    // MARK: - Processing
    static let processingHeader = "Processing"
    static let providerLabel = "Reflect processing"

    // One short sentence. Avoid dense explanations in primary Settings rows.
    static let processingFootnote =
    "Choose where responses are generated. Cloud Tap sends selected text to the cloud when you choose it."

    static let appleProviderFootnote =
    "Uses Apple's on-device model on compatible devices. Responses may be simpler than Cloud Tap."

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
            .environmentObject(ClarityReflectStore())
            .environmentObject(ContemplationProviderSettings())
            .environmentObject(RedactionDictionary())
            .environmentObject(CapsuleStore())
    }
}
