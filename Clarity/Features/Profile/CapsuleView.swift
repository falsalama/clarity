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
    @State private var dharmaTraditionSelection: String = "" // e.g. Drikung, Kadampa, etc. (sub-lineage / movement)

    @State private var dharmaRoleSelection: String = ""
    @State private var dharmaExperienceSelection: String = ""
    @State private var dharmaStudyLevelSelection: String = ""
    @State private var dharmaPracticeRegionSelection: String = ""

    @State private var dharmaPracticesSelected: Set<String> = []
    @State private var dharmaDeitiesSelected: Set<String> = []
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
        static let dharmaMilestones = "dharma:milestones"
    }

    // MARK: - Option sets

    private let languageOptions: [String] = [
            "",
            "English",
            "French",
            "German",
            "Spanish",
            "Italian",
            "Portuguese",
            "Dutch",
            "Russian",
            "Arabic",
            "Hindi",
            "Nepali",
            "Sinhala",
            "Thai",
            "Burmese",
            "Vietnamese",
            "Khmer",
            "Lao",
            "Mongolian",
            "Chinese (Mandarin)",
            "Cantonese",
            "Japanese",
            "Korean",
            "Tibetan"
        ]

    private let regionOptions: [String] = [
          "",
          "Europe (other)",
          "North America",
          "Latin America",
          "North Africa",
          "Sub-Saharan Africa",
          "Middle East",
          "South Asia",
          "Southeast Asia",
          "East Asia",
          "Central Asia",
          "Oceania",
          "Online / Remote",
          "Other"
    ]

    private let countryOptions: [String] = [
            "",
            "United Kingdom",
            "Ireland",
            "France",
            "Germany",
            "Spain",
            "Italy",
            "Netherlands",
            "Belgium",
            "Switzerland",
            "Austria",
            "Sweden",
            "Norway",
            "Denmark",
            "Poland",
            "Czechia",
            "Greece",
            "Portugal",
            "United States",
            "Canada",
            "Mexico",
            "Brazil",
            "Argentina",
            "Australia",
            "New Zealand",
            "India",
            "Nepal",
            "Bhutan",
            "Sri Lanka",
            "Pakistan",
            "Bangladesh",
            "Myanmar (Burma)",
            "Thailand",
            "Laos",
            "Cambodia",
            "Vietnam",
            "Malaysia",
            "Singapore",
            "Indonesia",
            "Philippines",
            "China",
            "Hong Kong",
            "Taiwan",
            "Mongolia",
            "Japan",
            "South Korea",
            "North Korea",
            "Tibet (region)",
            "Russia",
            "Other"
        ]

    private let dharmaVehicleOptions: [String] = [
        "", "Theravāda", "Mahāyāna", "Vajrayāna", "Other / Mixed"
    ]

    private let dharmaSchoolOptions: [String] = [
        "",
        "Theravāda",
        "Zen (Chan/Seon/Thiền)",
        "Pure Land",
        "Tiantai / Tendai",
        "Nichiren",
        "Kagyu",
        "Sakya",
        "Gelug",
        "Jonang",
        "Bön",
        "Shingon",
        "Nyingma",
        "Other / Mixed"
    ]

    private let dharmaTraditionOptions: [String] = [
        "",
        "FPMT",
        "Rimé (non-sectarian)",
        "Rigpa",
        "Drikung Kagyu",
        "Karma Kagyu",
        "Drukpa Kagyu",
        "Shangpa Kagyu",
        "Thai Forest",
        "Insight Meditation",
        "Plum Village",
        "Vipassanā (Goenka)",
        "Other / Mixed"
    ]
    private let dharmaPracticeRegionOptions: [String] = [
        "",
            "UK & Ireland",
            "Europe (other)",
            "North America",
            "Latin America",
            "Middle East",
            "Africa",
            "India",
            "Nepal",
            "Bhutan",
            "Sri Lanka",
            "Myanmar (Burma)",
            "Thailand",
            "Laos / Cambodia / Vietnam",
            "Malaysia / Singapore / Indonesia",
            "China / Hong Kong / Taiwan",
            "Japan",
            "Korea",
            "Mongolia",
            "Tibet / Himalayan region",
            "Online / Remote",
            "Other"
        ]

    private let dharmaRoleOptions: [String] = [
        "",
           "Lay practitioner",
           "Lay teacher / facilitator",
           "Novice monastic",
           "Nun (bhikkhunī)",
           "Monk (bhikkhu)",
           "Monastic (unspecified)",
           "Ngakpa / Ngakma (Ngagpa/Ngagma)",
           "Tantric Practitioner",
           "Yogi / Yogini",
           "Teacher",
           "Lama / Rinpoche",
           "Tulku",
           "Abbott / Abbess",
           "Retreatant",
           "Chant leader / umdze",
           "Translator / interpreter",
           "Scholar / researcher",
           "Other"
       ]

    private let dharmaExperienceOptions: [String] = [
        "", "< 1 year", "1–3 years", "3–7 years", "7–15 years", "15+ years"
    ]

    private let dharmaStudyLevelOptions: [String] = [
        "", "Beginner", "Intermediate", "Advanced", "Scholar", "Practitioner-focused"
    ]

    private let dharmaPracticeOptions: [String] = [
        // Core meditation streams
            "Dzogchen",
            "Mahāmudrā",
            "Shamatha",
            "Vipashyana",

            // Foundational / training systems
            "Ngöndro",
            "Lamrim",
            "Lojong",
            "Tonglen",
            "Satipaṭṭhāna",
            "Mindfulness of breathing (Ānāpānasati)",
            "Metta (loving-kindness)",

            // Vajrayana methods (kept broad / non-controversial)
            "Mantra recitation",
            "Yidam / Deity yoga",
            "Guru yoga",
            "Vajrasattva purification",
            "Chöd",
            "Phowa",
            "Tummo (inner heat)",
            "Six Yogas of Naropa (general)",

            // Major devotional practices (big + common)
            "Chenrezig / Avalokiteshvara",
            "Guānyīn (Avalokiteshvara)",
            "Tārā",
            "Amitābha / Amitāyus (Pure Land / long life)",

            // Zen / East Asian
            "Zazen / Shikantaza",
            "Koan practice",
            "Pure Land nianfo / nembutsu",

            // Study (optional but useful)
            "Madhyamaka study",
            "Abhidharma study",
            "Prajñāpāramitā study",

            // Aspiration / prayer (broad)
            "Monlam (aspiration prayers)"
        ]

    private let dharmaDeityOptions: [String] = [
        "",
            "Shakyamuni Buddha",
            "Amitabha (Amida / Amituofo)",
            "Medicine Buddha (Bhaisajyaguru / Yakushi / Yaoshi)",
            "Avalokiteshvara (Chenrezig / Guanyin / Kannon)",
            "Manjushri (Wenshu / Monju)",
            "Vajrapani",
            "Kshitigarbha (Jizo)",
            "Maitreya (Miroku)",
            "Samantabhadra (Puxian / Fugen)",

            "Tara (Green / White)",
            "Vajrasattva (Dorje Sempa)",
            "Guru Rinpoche (Padmasambhava)",

            "Kalachakra",
            "Vajrayogini",
            "Chakrasamvara",
            "Hevajra",
            "Guhyasamaja",
            "Yamantaka (Vajrabhairava)",
            "Vajrakilaya",
            "Hayagriva",

            "Acala (Fudo Myo-o)",
            "Mahakala",

            "Other"
        ]

    private let dharmaMilestoneOptions: [String] = [
        "",

           // Foundational commitment
           "Taken Refuge",
           "Undertaken Bodhisattva Vows",
           "Undertaken Tantric Vows",

           // Practice completions
           "Completed Ngöndro",
           "Completed Major Retreat (1+ month)",
           "Completed 3-Year Retreat",

           // Study milestones
           "Completed Lamrim Course",
           "Completed Structured Dharma Study Program",

           // Ordination
           "Lay Precepts Taken",
           "Ordained Monastic",
           "Ordained Ngakpa / Ngakma",

           // Tantric context (neutral phrasing)
           "Received Empowerment (Wang)",

           "Other"
       ]

    var body: some View {
        List {
            structuredProfileSection
            structuredDharmaSection
            preferencesSection
            advancedSection
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

            // Dharma multi (typed; no CSV)
            dharmaPracticesSelected = Set(store.multiSelect(.dharmaPractices))
            dharmaDeitiesSelected = Set(store.multiSelect(.dharmaDeities))
            dharmaMilestonesSelected = Set(store.multiSelect(.dharmaMilestones))
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
                    store.setMultiSelect(.dharmaPractices, values: Array(dharmaPracticesSelected).sorted())
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
                    store.setMultiSelect(.dharmaDeities, values: Array(dharmaDeitiesSelected).sorted())
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
                    title: "Milestones",
                    options: dharmaMilestoneOptions,
                    selection: $dharmaMilestonesSelected
                ) {
                    store.setMultiSelect(.dharmaMilestones, values: Array(dharmaMilestonesSelected).sorted())
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
                Text("No preferences yet.")
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
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Add") {
                        addPreference()
                    }
                    .disabled(!canAddPreference)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section("Advanced") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pseudonym (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("e.g. a nickname", text: $pseudonymDraft)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .pseudonym)
                    .onSubmit {
                        store.setPseudonym(pseudonymDraft)
                        focusedField = nil
                        hideKeyboard()
                    }

                HStack {
                    Spacer()
                    Button("Save pseudonym") {
                        store.setPseudonym(pseudonymDraft)
                        focusedField = nil
                        hideKeyboard()
                    }
                }
            }

            Button(role: .destructive) {
                store.wipe()
            } label: {
                Text("Wipe capsule (delete all)")
            }
            .accessibilityHint("Deletes all preferences and notes from your Capsule.")
        }
    }

    // MARK: - Validation

    private var validationMessage: String? {
        let k = normaliseKey(newPrefKey)
        if k.isEmpty { return nil }
        if !k.contains(where: { $0.isLetter || $0.isNumber }) { return "Key must contain letters/numbers." }
        if k.count > 64 { return "Key too long (max 64)." }
        if newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines).count > 128 { return "Value too long (max 128)." }
        return nil
    }

    private var canAddPreference: Bool {
        let k = normaliseKey(newPrefKey)
        let v = newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return !k.isEmpty && !v.isEmpty && validationMessage == nil
    }

    // MARK: - Actions

    private func setPrefOrClear(key: String, value: String) {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.isEmpty {
            store.removePreference(key: key)
        } else {
            store.setPreference(key: key, value: v)
        }
    }

    private func addPreference() {
        guard canAddPreference else { return }
        let k = normaliseKey(newPrefKey)
        let v = newPrefValue.trimmingCharacters(in: .whitespacesAndNewlines)

        store.setPreference(key: k, value: v)

        newPrefKey = ""
        newPrefValue = ""
        focusedField = .label
    }

    // MARK: - Helpers

    private func prefValue(_ key: String) -> String {
        store.capsule.preferences.extras[key] ?? ""
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

// MARK: - Small helpers

private struct PreferencePickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let onChange: (String) -> Void

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option.isEmpty ? "—" : option).tag(option)
            }
        }
        .onChange(of: selection) { _, newValue in
            onChange(newValue)
        }
    }
}

private struct MultiSelectList: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>
    let onDone: () -> Void

    var body: some View {
        List {
            ForEach(options, id: \.self) { opt in
                Button {
                    if selection.contains(opt) {
                        selection.remove(opt)
                    } else {
                        selection.insert(opt)
                    }

                    // SAVE IMMEDIATELY (so Back works, Done not required)
                    onDone()
                } label: {
                    HStack {
                        Text(opt)
                        Spacer()
                        if selection.contains(opt) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            // Keep button for UX familiarity, but it's no longer required.
            Button("Done") {
                onDone()
            }
        }
        // Safety: if user presses Back without hitting Done after last change.
        .onDisappear {
            onDone()
        }
    }
}
