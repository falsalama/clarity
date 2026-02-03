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
            Section {
                Text(LocalizedStringKey("settings.local_first"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // NEW: Profile / learning
            Section {
                NavigationLink {
                    CapsuleView()
                } label: {
                    Text("Capsule")
                }

                NavigationLink {
                    LearningView()
                } label: {
                    Text("Learning")
                }

                Text("Optional. Keeps a small, local profile to improve responses. You can switch it off or clear it any time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About you")
            }

            Section {
                if dictionary.tokens.isEmpty {
                    Text(LocalizedStringKey("settings.redaction.empty"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dictionary.tokens, id: \.self) { token in
                        Text(token)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    .onDelete(perform: dictionary.remove)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField(LocalizedStringKey("settings.redaction.add.placeholder"), text: $newToken)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .onSubmit { addToken() }

                    HStack(spacing: 10) {
                        Button {
                            addToken()
                        } label: {
                            Text(LocalizedStringKey("settings.redaction.add"))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTokenTrimmed.isEmpty)

                        Button("Done") {
                            hideKeyboard()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)

            } header: {
                Text(LocalizedStringKey("settings.redaction.header"))
            } footer: {
                Text(LocalizedStringKey("settings.redaction.footer"))
            }

            if !dictionary.tokens.isEmpty {
                Section {
                    Button(role: .destructive) {
                        hideKeyboard()
                        confirmRemoveAll = true
                    } label: {
                        Text(LocalizedStringKey("settings.redaction.remove_all"))
                    }
                }
            }

            Section {
                NavigationLink {
                    PrivacyView()
                } label: {
                    Text(LocalizedStringKey("settings.privacy.link"))
                }

                Text(LocalizedStringKey("settings.privacy.note"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(LocalizedStringKey("settings.privacy.header"))
            }
        }
        .navigationTitle(Text(LocalizedStringKey("settings.title")))
        .confirmationDialog(
            Text(LocalizedStringKey("settings.redaction.remove_all.confirm.title")),
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey("settings.redaction.remove_all.confirm.ok"), role: .destructive) {
                dictionary.wipe()
            }
            Button(LocalizedStringKey("settings.redaction.remove_all.confirm.cancel"), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey("settings.redaction.remove_all.confirm.message"))
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

