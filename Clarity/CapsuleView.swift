import SwiftUI

struct CapsuleView: View {
    @EnvironmentObject private var store: CapsuleStore

    @State private var newPrefKey: String = ""
    @State private var newPrefValue: String = ""

    @State private var newCondKey: String = ""
    @State private var newCondValue: String = ""

    var body: some View {
        List {
            Section {
                Text("Capsule stores abstracted preferences and conditions only. No transcripts, no identities.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            preferencesSection
            conditionsSection

            Section {
                HStack {
                    Text("Updated")
                    Spacer()
                    Text(store.capsule.updatedAt)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Section {
                Button(role: .destructive) { store.wipe() } label: {
                    Text("Wipe Capsule")
                }
                .accessibilityLabel("Wipe Capsule")
                .accessibilityHint("Deletes all preferences, conditions, and notes from your Capsule.")
            }
        }
        .navigationTitle("Capsule")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            if store.capsule.preferences.isEmpty {
                Text("None yet.")
                    .foregroundStyle(.secondary)
            } else {
                let keys = store.capsule.preferences.keys.sorted()
                ForEach(keys, id: \.self) { k in
                    HStack {
                        Text(k)
                        Spacer()
                        Text(store.capsule.preferences[k] ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    let keys = store.capsule.preferences.keys.sorted()
                    for i in offsets {
                        guard keys.indices.contains(i) else { continue }
                        store.removePreference(key: keys[i])
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Key (e.g. tone)", text: $newPrefKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Value (e.g. neutral)", text: $newPrefValue)

                Button("Add preference") { addPreference() }
                    .disabled(isBlank(newPrefKey) || isBlank(newPrefValue))
            }
        }
    }

    private var conditionsSection: some View {
        Section("Conditions") {
            if store.capsule.conditions.isEmpty {
                Text("None yet.")
                    .foregroundStyle(.secondary)
            } else {
                let keys = store.capsule.conditions.keys.sorted()
                ForEach(keys, id: \.self) { k in
                    HStack {
                        Text(k)
                        Spacer()
                        Text(store.capsule.conditions[k] ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    let keys = store.capsule.conditions.keys.sorted()
                    for i in offsets {
                        guard keys.indices.contains(i) else { continue }
                        store.removeCondition(key: keys[i])
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Key (e.g. driving_mode)", text: $newCondKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Value (e.g. capture_only)", text: $newCondValue)

                Button("Add condition") { addCondition() }
                    .disabled(isBlank(newCondKey) || isBlank(newCondValue))
            }
        }
    }

    private func addPreference() {
        let k = normaliseKey(newPrefKey)
        let v = newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return }
        store.setPreference(key: k, value: v)
        newPrefKey = ""
        newPrefValue = ""
    }

    private func addCondition() {
        let k = normaliseKey(newCondKey)
        let v = newCondValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return }
        store.setCondition(key: k, value: v)
        newCondKey = ""
        newCondValue = ""
    }

    private func normaliseKey(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return "" }

        let underscored = trimmed
            .replacingOccurrences(of: #"[\s\-]+"#, with: "_", options: .regularExpression)
            .replacingOccurrences(of: #"_{2,}"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return underscored
    }

    private func isBlank(_ s: String) -> Bool {
        s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    NavigationStack {
        CapsuleView()
            .environmentObject(CapsuleStore())
    }
}

