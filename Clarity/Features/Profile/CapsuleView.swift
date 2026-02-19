import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CapsuleView: View {
    @EnvironmentObject private var store: CapsuleStore

    @State private var newPrefKey: String = ""
    @State private var newPrefValue: String = ""
    @State private var pseudonymDraft: String = ""

    // Structured fields (stored into CapsuleStore as extras via store.setPreference)
    @State private var languageSelection: String = ""
    @State private var regionSelection: String = ""
    @State private var countrySelection: String = ""

    @State private var dharmaVehicleSelection: String = ""
    @State private var dharmaSchoolSelection: String = ""
    @State private var dharmaTraditionSelection: String = ""

    @State private var dharmaRoleSelection: String = ""
    @State private var dharmaExperienceSelection: String = ""
    @State private var dharmaStudyLevelSelection: String = ""
    @State private var dharmaPracticeRegionSelection: String = ""

    @State private var dharmaPracticesSelected: Set<String> = []
    @State private var dharmaDeitiesSelected: Set<String> = []
    @State private var dharmaTermsSelected: Set<String> = []
    @State private var dharmaMilestonesSelected: Set<String> = []

    private enum Field: Hashable { case label, value, pseudonym }
    @FocusState private var focusedField: Field?

    private var isEditing: Bool { focusedField != nil }

    // MARK: - Preference keys (stable)

    private enum PrefKey {
        static let language = "profile:language"
        static let region = "profile:region"
        static let country = "profile:country"

        static let dharmaVehicle = "dharma:vehicle"
        static let dharmaSchool = "dharma:school"
        static let dharmaTradition = "dharma:tradition"

        static let dharmaRole = "dharma:role"
        static let dharmaExperience = "dharma:experience"
        static let dharmaStudyLevel = "dharma:study_level"
        static let dharmaPracticeRegion = "dharma:practice_region"

        static let dharmaPractices = "dharma:practices"
        static let dharmaDeities = "dharma:deities"
        static let dharmaTerms = "dharma:terms"
        static let dharmaMilestones = "dharma:milestones"
    }

    // MARK: - Option sets

    private let languageOptions: [String] = [
        "", "English", "French", "German", "Spanish", "Italian",
        "Japanese", "Chinese (Mandarin)", "Chinese (Cantonese)", "Hindi", "Tibetan", "Other"
    ]

    private let regionOptions: [String] = [
        "", "Europe", "UK", "North America", "South America", "Middle East",
        "Africa", "South Asia", "East Asia", "South East Asia", "Oceania", "Other"
    ]

    private let countryOptions: [String] = [
        "", "UK", "Ireland", "USA", "Canada", "Australia", "New Zealand",
        "France", "Germany", "Spain", "Italy", "Netherlands", "Sweden", "Norway", "Denmark",
        "Switzerland", "Austria", "Belgium", "Portugal", "Greece", "Poland", "Czechia",
        "Hungary", "Romania", "Bulgaria", "Turkey", "Ukraine", "Russia", "Israel", "UAE",
        "Saudi Arabia", "Egypt", "South Africa", "Nigeria", "Kenya", "Ghana",
        "India", "Pakistan", "Bangladesh", "Sri Lanka", "Nepal", "Bhutan",
        "China", "Hong Kong", "Taiwan", "South Korea", "Singapore", "Malaysia",
        "Indonesia", "Thailand", "Vietnam", "Philippines", "Japan", "Mongolia", "Tibet",
        "Myanmar (Burma)",
        "Other"
    ]

    private let dharmaVehicleOptions: [String] = [
        "",
        "Theravāda",
        "Mahayana",
        "Vajrayana",
        "Zen/Chan",
        "Bön",
        "Secular / Pragmatic"
    ]

    private let dharmaSchoolOptions: [String] = [
        "",
        "Nyingma",
        "Kagyu",
        "Gelug",
        "Sakya",
        "Jonang",
        "Rimé (Non-sectarian)",
        "Kadampa / New Kadampa",
        "Zen/Chan",
        "Theravāda",
        "Other"
    ]

    private let dharmaTraditionOptions: [String] = [
        "",
        "Drikung Kagyu",
        "Karma Kagyu",
        "Drukpa Kagyu",
        "Shangpa Kagyu",
        "FPMT",
        "Triratna",
        "Mahasi",
        "Goenka",
        "Other"
    ]

    private let dharmaRoleOptions: [String] = [
        "",
        "Lay practitioner",
        "Lay vows",
        "Ordained",
        "Ngagpa/Ngagmo",
        "Monastic",
        "Teacher",
        "Lama",
        "Rinpoche",
        "Tulku",
        "Tertön",
        "Khenpo",
        "Geshe",
        "Roshi",
        "Ajahn",
        "Sayadaw",
        "Dr."
    ]

    private let dharmaExperienceOptions: [String] = [
        "", "Beginner", "Some experience", "Long-term", "Very experienced"
    ]

    private let dharmaStudyLevelOptions: [String] = [
        "",
        "Short course",
        "1 month course",
        "6 month course",
        "1 year course",
        "2 year course",
        "3 year retreat",
        "Degree (BA/MA)",
        "PhD",
        "Other"
    ]

    private let dharmaPracticeRegionOptions: [String] = [
        "",
        "Tibet",
        "India",
        "Nepal",
        "Bhutan",
        "Mongolia",
        "China",
        "Japan",
        "Thailand",
        "Myanmar (Burma)",
        "Vietnam",
        "Sri Lanka",
        "Russia",
        "Korea",
        "Western / Europe",
        "North America",
        "Other"
    ]

    private let dharmaPracticeOptions: [String] = [
        "Refuge",
        "Bodhicitta",
        "Lay vows",
        "Monastic vows",
        "Ngöndro",
        "Ngöndro completed",

        "Shamatha",
        "Vipashyana/Vipassana",
        "Shiné",
        "Lhatong",
        "Zazen",
        "Koan practice",
        "Metta",
        "Tonglen",
        "Lojong",
        "Lamrim",

        "Mantra recitation",
        "Sādhana",
        "Tantric practice",
        "Guru yoga",
        "Vajrasattva",
        "Tsok/Ganachakra",
        "Chöd",
        "Phowa",
        "Tummo",
        "Dream yoga",
        "Generation stage",
        "Completion stage",
        "Mahamudra",
        "Dzogchen",
        "Trekchö",
        "Thögal",

        "Thangka painting"
    ]

    private let dharmaDeityOptions: [String] = [
        "Tara",
        "Green Tara",
        "White Tara",
        "Avalokiteshvara/Chenrezig",
        "Manjushri",
        "Vajrapani",
        "Medicine Buddha",
        "Amitabha",
        "Shakyamuni",
        "Padmasambhava/Guru Rinpoche",
        "Yeshe Tsogyal",
        "Vajrayogini",
        "Vajrakilaya",
        "Chakrasamvara",
        "Hevajra",
        "Yamantaka/Vajrabhairava",
        "Kalachakra"
    ]

    private let dharmaTermOptions: [String] = [
        "Sutra",
        "Tantra",
        "Mantra/Dharani",
        "Empowerment (wang/dbang)",
        "Reading transmission (lung)",
        "Tri (instruction)",
        "Samaya",
        "Purification/Confession",
        "Ngakso"
    ]

    private let dharmaMilestoneOptions: [String] = [
        "Taken refuge",
        "Lay vows",
        "Monastic vows",
        "Ordained",
        "Ngagpa ordained",
        "Ngöndro completed",
        "One-year retreat",
        "Three-year retreat",
        "Empowerments (general)",
        "Reading transmissions (lung)"
    ]

    var body: some View {
        List {
            Section { EmptyView() }

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

            structuredProfileSection
            structuredDharmaSection
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
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                Color.clear
                    .frame(height: 56)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Pseudonym
            pseudonymDraft = store.capsule.preferences.pseudonym ?? ""

            // Profile
            languageSelection = prefValue(PrefKey.language)
            regionSelection = prefValue(PrefKey.region)
            countrySelection = prefValue(PrefKey.country)

            // Dharma singles
            dharmaVehicleSelection = prefValue(PrefKey.dharmaVehicle)
            dharmaSchoolSelection = prefValue(PrefKey.dharmaSchool)
            dharmaTraditionSelection = prefValue(PrefKey.dharmaTradition)
            dharmaRoleSelection = prefValue(PrefKey.dharmaRole)
            dharmaExperienceSelection = prefValue(PrefKey.dharmaExperience)
            dharmaStudyLevelSelection = prefValue(PrefKey.dharmaStudyLevel)
            dharmaPracticeRegionSelection = prefValue(PrefKey.dharmaPracticeRegion)

            // Dharma multi
            dharmaPracticesSelected = parseCSVSet(prefValue(PrefKey.dharmaPractices))
            dharmaDeitiesSelected = parseCSVSet(prefValue(PrefKey.dharmaDeities))
            dharmaTermsSelected = parseCSVSet(prefValue(PrefKey.dharmaTerms))
            dharmaMilestonesSelected = parseCSVSet(prefValue(PrefKey.dharmaMilestones))
        }
    }

    // MARK: - Structured sections

    private var structuredProfileSection: some View {
        Section("Profile") {
            PreferencePickerRow(
                title: "Language",
                selection: $languageSelection,
                options: languageOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.language, value: newValue)
            }

            PreferencePickerRow(
                title: "Region",
                selection: $regionSelection,
                options: regionOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.region, value: newValue)
            }

            PreferencePickerRow(
                title: "Country",
                selection: $countrySelection,
                options: countryOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.country, value: newValue)
            }
        }
    }

    private var structuredDharmaSection: some View {
        Section("Dharma") {
            PreferencePickerRow(
                title: "Vehicle",
                selection: $dharmaVehicleSelection,
                options: dharmaVehicleOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaVehicle, value: newValue)
            }

            PreferencePickerRow(
                title: "School",
                selection: $dharmaSchoolSelection,
                options: dharmaSchoolOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaSchool, value: newValue)
            }

            PreferencePickerRow(
                title: "Tradition",
                selection: $dharmaTraditionSelection,
                options: dharmaTraditionOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaTradition, value: newValue)
            }

            PreferencePickerRow(
                title: "Role",
                selection: $dharmaRoleSelection,
                options: dharmaRoleOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaRole, value: newValue)
            }

            PreferencePickerRow(
                title: "Experience",
                selection: $dharmaExperienceSelection,
                options: dharmaExperienceOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaExperience, value: newValue)
            }

            PreferencePickerRow(
                title: "Study Level",
                selection: $dharmaStudyLevelSelection,
                options: dharmaStudyLevelOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaStudyLevel, value: newValue)
            }

            PreferencePickerRow(
                title: "Practice Region",
                selection: $dharmaPracticeRegionSelection,
                options: dharmaPracticeRegionOptions
            ) { newValue in
                setPrefOrClear(key: PrefKey.dharmaPracticeRegion, value: newValue)
            }

            NavigationLink {
                MultiSelectList(
                    title: "Practices",
                    options: dharmaPracticeOptions,
                    selection: $dharmaPracticesSelected
                ) {
                    setPrefOrClear(key: PrefKey.dharmaPractices, value: toCSV(dharmaPracticesSelected))
                }
            } label: {
                LabeledContent("Practices") {
                    Text(summaryText(for: dharmaPracticesSelected))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            NavigationLink {
                MultiSelectList(
                    title: "Deities",
                    options: dharmaDeityOptions,
                    selection: $dharmaDeitiesSelected
                ) {
                    setPrefOrClear(key: PrefKey.dharmaDeities, value: toCSV(dharmaDeitiesSelected))
                }
            } label: {
                LabeledContent("Deities") {
                    Text(summaryText(for: dharmaDeitiesSelected))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            NavigationLink {
                MultiSelectList(
                    title: "Terms",
                    options: dharmaTermOptions,
                    selection: $dharmaTermsSelected
                ) {
                    setPrefOrClear(key: PrefKey.dharmaTerms, value: toCSV(dharmaTermsSelected))
                }
            } label: {
                LabeledContent("Terms") {
                    Text(summaryText(for: dharmaTermsSelected))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            NavigationLink {
                MultiSelectList(
                    title: "Milestones",
                    options: dharmaMilestoneOptions,
                    selection: $dharmaMilestonesSelected
                ) {
                    setPrefOrClear(key: PrefKey.dharmaMilestones, value: toCSV(dharmaMilestonesSelected))
                }
            } label: {
                LabeledContent("Milestones") {
                    Text(summaryText(for: dharmaMilestonesSelected))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Preferences (freeform)

    private var preferencesSection: some View {
        Section("Preferences") {
            // Hide structured keys from this list, but they still persist + inject.
            let pairs = store.preferenceKeyValues.filter { kv in
                let k = kv.key
                if k.hasPrefix("profile:") { return false }
                if k.hasPrefix("dharma:") { return false }
                return true
            }

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
                    let pairs = store.preferenceKeyValues.filter { kv in
                        let k = kv.key
                        if k.hasPrefix("profile:") { return false }
                        if k.hasPrefix("dharma:") { return false }
                        return true
                    }
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

    private func setPrefOrClear(key: String, value: String) {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.isEmpty {
            store.removePreference(key: key)
        } else {
            store.setPreference(key: key, value: v)
        }
    }

    /// IMPORTANT: read directly from extras so structured keys always load,
    /// even if the UI hides them from the Preferences list.
    private func prefValue(_ key: String) -> String {
        store.capsule.preferences.extras[key] ?? ""
    }

    private func parseCSVSet(_ value: String) -> Set<String> {
        let parts = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(parts)
    }

    private func toCSV(_ set: Set<String>) -> String {
        set.sorted().joined(separator: ", ")
    }

    private func summaryText(for set: Set<String>) -> String {
        if set.isEmpty { return "None" }
        if set.count == 1 { return set.first ?? "1 selected" }
        return "\(set.count) selected"
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

// MARK: - Components

private struct PreferencePickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let onCommit: (String) -> Void

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { v in
                Text(v.isEmpty ? "None" : v).tag(v)
            }
        }
        .onChange(of: selection) { _, newValue in
            onCommit(newValue)
        }
    }
}

private struct MultiSelectList: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>
    let onCommit: () -> Void

    var body: some View {
        List {
            ForEach(options, id: \.self) { option in
                Button {
                    if selection.contains(option) {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                    onCommit()
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if selection.contains(option) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        CapsuleView()
            .environmentObject(CapsuleStore())
    }
}

