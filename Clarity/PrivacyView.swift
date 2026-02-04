// PrivacyView.swift
import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var cloudTap: CloudTapSettings

    @State private var confirmDisable = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio and raw transcripts stay on this device.")
                    Text("Redaction is applied before data is sent.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Toggle(isOn: enableBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Cloud Tap")
                        Text("You confirm each send.")
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

                NavigationLink("View Send Preview") {
                    PayloadPreviewExplainerView()
                }
            } header: {
                Text("Data sharing")
            } footer: {
                Text("Preview exactly what would be sent for a specific action.")
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
                Text("Preview what would be sent when you choose Cloud Tap for an action. Includes redacted text, timing, and limited context.")
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
            }
        }
        .navigationTitle("Send Preview")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
