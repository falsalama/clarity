import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var cloudTap: CloudTapSettings

    @State private var newToken: String = ""
    @State private var confirmRemoveAll = false

    var body: some View {
        List {
            Section {
                Text(String(localized: "settings.local_first"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                if dictionary.tokens.isEmpty {
                    Text(String(localized: "settings.redaction.empty"))
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
                    TextField(String(localized: "settings.redaction.add.placeholder"), text: $newToken)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)

                    Button(String(localized: "settings.redaction.add")) { addToken() }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTokenTrimmed.isEmpty)
                }
                .padding(.vertical, 4)

            } header: {
                Text(String(localized: "settings.redaction.header"))
            } footer: {
                Text(String(localized: "settings.redaction.footer"))
            }

            if !dictionary.tokens.isEmpty {
                Section {
                    Button(role: .destructive) {
                        confirmRemoveAll = true
                    } label: {
                        Text(String(localized: "settings.redaction.remove_all"))
                    }
                }
            }

            Section {
                NavigationLink(String(localized: "settings.privacy.link")) { PrivacyView() }

                Text(String(localized: "settings.privacy.note"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "settings.privacy.header"))
            }
        }
        .navigationTitle(String(localized: "settings.title"))
        .toolbar { EditButton() }
        .confirmationDialog(
            String(localized: "settings.redaction.remove_all.confirm.title"),
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.redaction.remove_all.confirm.ok"), role: .destructive) {
                dictionary.wipe()
            }
            Button(String(localized: "settings.redaction.remove_all.confirm.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.redaction.remove_all.confirm.message"))
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
    }
}

