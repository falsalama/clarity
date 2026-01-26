// PayloadPreviewView.swift
import SwiftUI

struct CloudTapPayload: Codable {
    struct Metadata: Codable {
        let turnId: String
        let timestampISO8601: String
        let mode: String
        let lane: String
    }

    let redactedTranscript: String
    let capsuleSummary: String?
    let metadata: Metadata
}

struct PayloadPreviewView: View {
    let payload: CloudTapPayload

    var body: some View {
        List {
            Section {
                Text("Redacted text only. No audio. No raw transcript.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Payload (JSON)") {
                ScrollView {
                    Text(prettyJSON(payload) ?? "{}")
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }

                Button("Copy JSON") { copyToPasteboard(prettyJSON(payload) ?? "{}") }
            }

            Section("Fields") {
                LabeledContent("Lane", value: payload.metadata.lane)
                LabeledContent("Mode", value: payload.metadata.mode)
                LabeledContent("Turn ID", value: payload.metadata.turnId)
                LabeledContent("Timestamp", value: payload.metadata.timestampISO8601)
            }
        }
        .navigationTitle("Payload Preview")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func prettyJSON<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func copyToPasteboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

