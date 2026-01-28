// CapsuleView.swift
import SwiftUI

struct CapsuleView: View {
    @EnvironmentObject private var store: CapsuleStore

    @State private var newPrefKey: String = ""
    @State private var newPrefValue: String = ""

    // Focus to support return-key flow between fields
    private enum Field: Hashable {
        case prefKey, prefValue
    }
    @FocusState private var focusedField: Field?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("""
Set optional preferences to influence responses.
""")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            preferencesSection

            Section {
                HStack {
                    Text("Updated")
                    Spacer()
                    Text(store.capsule.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Section {
                Button(role: .destructive) { store.wipe() } label: {
                    Text("Wipe Capsule")
                }
                .accessibilityLabel("Wipe Capsule")
                .accessibilityHint("Deletes all preferences and notes from your Capsule.")
            }
        }
        .navigationTitle("Capsule")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar { EditButton() }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            let pairs = store.preferenceKeyValues
            if pairs.isEmpty {
                Text("None yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pairs, id: \.key) { kv in
                    HStack {
                        Text(kv.key)
                        Spacer()
                        Text(kv.value)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(kv.key), \(kv.value)")
                }
                .onDelete { offsets in
                    let pairs = store.preferenceKeyValues
                    for i in offsets {
                        guard pairs.indices.contains(i) else { continue }
                        store.removePreference(key: pairs[i].key)
                    }
                }
            }

            // Add row
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Label") {
                    TextField("e.g. style, tone, region", text: $newPrefKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.none)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .prefKey)
                        .onSubmit { focusedField = .prefValue }
                }

                LabeledContent("Value") {
                    TextField("e.g. direct, concise, UK, EU", text: $newPrefValue)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .prefValue)
                        .onSubmit { addPreference() }
                }

                HStack {
                    if let validation = prefValidationMessage {
                        Text(validation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        addPreference()
                    } label: {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAddPref)
                    .accessibilityHint("Adds a new preference label and value")
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Validation

    private var canAddPref: Bool {
        let k = normaliseKey(newPrefKey)
        let v = newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return false }
        // Prevent duplicate keys
        return store.preferenceKeyValues.contains(where: { $0.key == k }) == false
    }

    private var prefValidationMessage: String? {
        let rawKey = newPrefKey
        let k = normaliseKey(rawKey)

        if !rawKey.isEmpty, k.isEmpty {
            return "Label is invalid."
        }
        if store.preferenceKeyValues.contains(where: { $0.key == k }) {
            return "Label already exists."
        }
        return nil
    }

    // MARK: - Actions

    private func addPreference() {
        let k = normaliseKey(newPrefKey)
        let v = newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return }
        guard store.preferenceKeyValues.contains(where: { $0.key == k }) == false else { return }

        store.setPreference(key: k, value: v)
        newPrefKey = ""
        newPrefValue = ""
        focusedField = .prefKey
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
}

#Preview {
    NavigationStack {
        CapsuleView()
            .environmentObject(CapsuleStore())
    }
}

