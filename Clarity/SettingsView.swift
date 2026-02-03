import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var dictionary: RedactionDictionary

    @State private var newToken: String = ""

    var body: some View {
        List {
            Section("Redaction") {
                if dictionary.tokens.isEmpty {
                    Text("No redaction terms yet.")
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

            Section("Privacy / Cloud Tap") {
                NavigationLink("Open Privacy / Cloud Tap") {
                    PrivacyView()
                }
            }
        }
        .navigationTitle("Settings")
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
