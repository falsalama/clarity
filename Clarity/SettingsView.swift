import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var cloudTap: CloudTapSettings

    @State private var newToken: String = ""
    @State private var confirmRemoveAll = false

    var body: some View {
        List {
            // Redaction terms
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

                    Button {
                        addToken()
                    } label: {
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

            // Safety (Driving / CarPlay)
            Section {
                LabeledContent("Driving / CarPlay") { Text("Capture only") }
                Text("Reflection and cloud actions are unavailable while driving.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Safety")
            }

#if DEBUG
            // Developer
            Section {
                Toggle(isOn: Binding(
                    get: { FeatureFlags.localWALBuildEnabled },
                    set: { FeatureFlags.localWALBuildEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable local WAL build")
                        Text("Generates WAL locally and updates learned cues (development only).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Developer")
            }
#endif
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            Text("Remove all redaction terms?"),
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove all", role: .destructive) {
                dictionary.wipe()
            }
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

