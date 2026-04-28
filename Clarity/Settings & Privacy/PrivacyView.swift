// PrivacyView.swift
import SwiftUI

struct PrivacyView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio and raw transcripts stay on this device.")
                    Text("Cloud Tap sends only the selected redacted text when you choose a cloud response.")
                    Text("Health data is used on device for gentle pattern context. It is not sent to Cloud Tap.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                LabeledContent("What can be sent") { Text("Redacted text only") }
                LabeledContent("Never sent") { Text("Audio, raw transcript, Health data") }
                LabeledContent("Per-call consent") { Text("Always required") }

                NavigationLink("View Send Preview") {
                    PayloadPreviewExplainerView()
                }
            } header: {
                Text("Data sharing")
            } footer: {
                Text("Preview exactly what would be sent for a specific action.")
            }

            Section {
                Text("Clarity supports reflection, practice, and Buddhist learning. It is not medical advice, therapy, diagnosis, treatment, or crisis support.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Scope")
            }
        }
        .navigationTitle("Privacy / Cloud Tap")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
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
                Text("Health data")
            }
        }
        .navigationTitle("Send Preview")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
