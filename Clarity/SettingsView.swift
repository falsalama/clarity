import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings

    @StateObject private var modelManager = LocalModelManager.shared

    @State private var newToken: String = ""
    @State private var confirmRemoveAll = false

    var body: some View {
        List {
            Section {
                Picker("Provider", selection: $providerSettings.choice) {
                    ForEach(ContemplationProviderSettings.Choice.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }

                Text(providerSettings.choice.footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if providerSettings.choice == .deviceTapApple {
                    Text("Device Tap (Apple) uses the system on-device model. It requires iOS 26+ and an Apple Intelligence-capable device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if providerSettings.choice == .deviceTapLlama {
                    Text("Device Tap (Llama) runs locally using an optional downloaded model: \(modelManager.modelNameForUI).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

            } header: {
                Text("Processing")
            }

            // Local model section only when Llama is selected
            if providerSettings.choice == .deviceTapLlama {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Expected file: \(modelManager.expectedFileNameForUI)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("Expected path:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(modelManager.expectedPathForUI)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Text("Exists: \(modelManager.existsForUI ? "Yes" : "No")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .foregroundColor(modelManager.existsForUI ? nil : .red)


                        Text("Size: \(modelManager.fileSizeBytesForUI) bytes")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    switch modelManager.state {
                    case .notInstalled:
                        Button("Download local model (~2 GB)") {
                            modelManager.startDownload()
                        }
                        Text("Downloaded to this device only. Required for Device Tap (Llama).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                    case .downloading:
                        ProgressView()
                        Text("Downloading…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                    case .ready:
                        LabeledContent("Status") { Text("Installed") }
                        Button("Delete local model", role: .destructive) {
                            modelManager.deleteModel()
                        }

                    case .failed(let message):
                        Text("Download failed: \(message)")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Retry download") {
                            modelManager.startDownload()
                        }
                    }

                    Button("Refresh model status") {
                        modelManager.refreshStatePublic()
                    }
                } header: {
                    Text("Local model")
                }
            }

            // Redaction
            Section("Redaction") {
                if dictionary.tokens.isEmpty {
                    Text("No redacted terms yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dictionary.tokens, id: \.self) { token in
                        Text(token)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    .onDelete(perform: dictionary.remove)
                }

                HStack(spacing: 10) {
                    TextField("Add a name or term to always redact", text: $newToken)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .onSubmit { addToken() }

                    Button { addToken() } label: {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTokenTrimmed.isEmpty)
                    .accessibilityLabel("Add redaction term")
                }
                .padding(.vertical, 4)
            }

            if !dictionary.tokens.isEmpty {
                Section {
                    Button(role: .destructive) {
                        hideKeyboard()
                        confirmRemoveAll = true
                    } label: {
                        Text("Remove all redaction terms")
                    }
                }
            }

            // Privacy / Cloud Tap
            Section {
                NavigationLink {
                    PrivacyView()
                } label: {
                    Text("Privacy / Cloud Tap")
                }

                Text("Audio and raw transcripts stay on this device. Redacted text only is used when you explicitly choose Cloud Tap.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Privacy")
            }

            // Transparency
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

            // Safety
            Section {
                LabeledContent("Driving / CarPlay") { Text("Capture only") }
                Text("Reflection and cloud actions are unavailable while driving.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Safety")
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            Text("Remove all redaction terms?"),
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove all", role: .destructive) { dictionary.wipe() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears your redaction list. You can add terms again at any time.")
        }
    }

    private var newTokenTrimmed: String {
        newToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addToken() {
        let t = newTokenTrimmed
        guard !t.isEmpty else { return }
        dictionary.add(t)
        newToken = ""
        hideKeyboard()
    }

    private func hideKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
#endif
    }
}

