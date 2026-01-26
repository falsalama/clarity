// PrivacyView.swift
import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var cloudTap: CloudTapSettings

    @State private var confirmDisable = false

    var body: some View {
        Form {
            Section {
                Text("Local-first. Audio and raw transcripts stay on this device. Redaction runs before anything else.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: enableBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Cloud Tap")
                        Text("Off by default. You still confirm each send.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Cloud Tap")
            } footer: {
                Text("Cloud Tap enables optional on-demand processing. Nothing is sent automatically.")
            }

            Section {
                LabeledContent("What can be sent") { Text("Redacted text only") }
                LabeledContent("Never sent") { Text("Audio, raw transcript") }
                LabeledContent("Per-call consent") { Text("Always required") }

                NavigationLink("View payload preview") {
                    PayloadPreviewExplainerView()
                }
            } header: {
                Text("Data sharing")
            } footer: {
                Text("The payload preview shows exactly what would be sent if you choose Cloud Tap for a specific action.")
            }

            Section {
                Toggle(isOn: $cloudTap.showLaneBadges) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show lane badges")
                        Text("Label outputs as Local / On-device / Cloud Tap.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Transparency")
            }

            Section {
                LabeledContent("Driving / CarPlay") { Text("Capture only") }
                Text("Reflection and cloud actions are disabled while driving.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Safety")
            }
        }
        .navigationTitle("Privacy / Cloud Tap")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .confirmationDialog(
            "Disable Cloud Tap?",
            isPresented: $confirmDisable,
            titleVisibility: .visible
        ) {
            Button("Disable", role: .destructive) { cloudTap.isEnabled = false }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Cloud Tap will remain off until you enable it again.")
        }
    }

    private var enableBinding: Binding<Bool> {
        Binding(
            get: { cloudTap.isEnabled },
            set: { newValue in
                if !newValue, cloudTap.isEnabled {
                    confirmDisable = true
                } else {
                    cloudTap.isEnabled = newValue
                }
            }
        )
    }
}

private struct PayloadPreviewExplainerView: View {
    var body: some View {
        List {
            Section {
                Text("Payload preview is local-only. It shows the redacted transcript and minimal metadata that would be sent if you explicitly choose Cloud Tap for a specific action.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Included") {
                Text("Redacted transcript")
                Text("Timestamp")
                Text("Capture context (minimal)")
                Text("Capsule summary (bounded)")
            }

            Section("Excluded") {
                Text("Audio files")
                Text("Raw transcript")
                Text("Contacts / identifiers")
            }
        }
        .navigationTitle("Payload preview")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

