import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CapsuleView: View {
    @EnvironmentObject private var store: CapsuleStore

    @State private var newPrefKey: String = ""
    @State private var newPrefValue: String = ""
    @State private var pseudonymDraft: String = ""

    private enum Field: Hashable { case label, value, pseudonym }
    @FocusState private var focusedField: Field?

    // Treat any focused field as “editing” to lift the footer above the keyboard accessory.
    private var isEditing: Bool { focusedField != nil }

    var body: some View {
        List {
            Section {
                // Intentionally empty (kept for spacing if you want later copy)
                EmptyView()
            }

            // Learning navigation
            Section {
                NavigationLink {
                    LearningView()
                } label: {
                    HStack {
                        Text("Learning")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Learning")
            }

            Section("Pseudonym") {
                TextField("Optional Pseudonym", text: $pseudonymDraft)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .textContentType(.nickname)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .pseudonym)
                    .onChange(of: pseudonymDraft) { _, newValue in
                        store.setPseudonym(newValue)
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
                Button(role: .destructive) {
                    focusedField = nil
                    hideKeyboard()
                    store.wipe()
                } label: {
                    Text("Wipe Capsule")
                }
                .accessibilityLabel("Wipe Capsule")
                .accessibilityHint("Deletes all preferences and notes from your Capsule.")
            }
        }
        .navigationTitle("Capsule")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    hideKeyboard()
                }
            }
        }
        // Add bottom inset only while editing so the footer isn't covered by the keyboard accessory.
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                Color.clear
                    .frame(height: 56) // adjust if your accessory bar is taller/shorter
                    .allowsHitTesting(false)
            }
        }
        // Initialise drafts once per appearance without clobbering active edits.
        .onAppear {
            if pseudonymDraft.isEmpty {
                pseudonymDraft = store.capsule.preferences.pseudonym ?? ""
            }
        }
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

            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Label") {
                    TextField("e.g. style, tone, region", text: $newPrefKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.none)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .label)
                        .onSubmit { focusedField = .value }
                }

                LabeledContent("Value") {
                    TextField("e.g. direct, concise, UK, EU", text: $newPrefValue)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .value)
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
        return store.preferenceKeyValues.contains(where: { $0.key == k }) == false
    }

    private var prefValidationMessage: String? {
        let rawKey = newPrefKey
        let k = normaliseKey(rawKey)

        if !rawKey.isEmpty, k.isEmpty { return "Label is invalid." }
        if store.preferenceKeyValues.contains(where: { $0.key == k }) { return "Label already exists." }
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
        focusedField = nil
        hideKeyboard()
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

    private func hideKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
#endif
    }
}

#Preview {
    NavigationStack {
        CapsuleView()
            .environmentObject(CapsuleStore())
    }
}
