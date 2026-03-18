import SwiftUI

struct CompassionView: View {
    @EnvironmentObject private var flow: AppFlowRouter
    @Environment(\.dismiss) private var dismiss

    @State private var loadedEntry: CompassionEntry?
    @State private var loadError: String?
    @State private var isLoading = true

    @AppStorage("compassion_current_day_index")
    private var currentCompassionDayIndex: Int = 1

    @AppStorage("compassion_last_completed_day_index")
    private var lastCompletedCompassionDayIndex: Int = 0

    @AppStorage("compassion_last_done_day_key")
    private var lastDoneDayKey: String = ""

    private let compassionFill = Color(red: 0.62, green: 0.28, blue: 0.34)

    private struct CompassionEntry: Identifiable, Equatable, Codable {
        let id: String
        let theme: String
        let meaning: String
        let practices: [String]
        let teaching: String
        let sortOrder: Int?
        let isPublished: Bool?

        enum CodingKeys: String, CodingKey {
            case id
            case theme
            case meaning
            case practices
            case teaching
            case sortOrder
            case isPublished
        }

        init(
            id: String,
            theme: String,
            meaning: String,
            practices: [String],
            teaching: String,
            sortOrder: Int? = nil,
            isPublished: Bool? = nil
        ) {
            self.id = id
            self.theme = theme
            self.meaning = meaning
            self.practices = practices
            self.teaching = teaching
            self.sortOrder = sortOrder
            self.isPublished = isPublished
        }
    }

    private struct CompassionStepsResponse: Codable {
        let dayIndex: Int
        let item: CompassionEntry?
    }

    private let fallbackEntry = CompassionEntry(
        id: "fallback_compassion_001",
        theme: "Let the frame widen.",
        meaning: "Self-concern narrows experience. Including others can soften pressure, widen perspective, and loosen afflictive heat.",
        practices: [
            "Pause once and consider what another person may be carrying.",
            "Let someone else matter in your attention, not as theory but as reality.",
            "When irritation appears, widen the frame before reacting."
        ],
        teaching: "Afflictive emotion narrows the field around \"me\" and \"my problem\". Compassion interrupts that contraction. It does not deny your own suffering - it stops it becoming the whole frame."
    )

    private var displayedEntry: CompassionEntry {
        loadedEntry ?? fallbackEntry
    }

    private var isUsingFallback: Bool {
        loadedEntry == nil
    }

    private var todayKey: String {
        Date().dayKey()
    }

    private var alreadyDoneToday: Bool {
        lastDoneDayKey == todayKey
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                dailyCard
                doneCard
                footerGlyph
            }
            .padding(16)
        }
        .background {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Compassion")
                        .font(.headline)

                    Text("kindness and perspective training")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .task(id: currentCompassionDayIndex) {
            syncDayIndexIfNeeded()
            await loadCompassionEntry()
        }
    }

    private func syncDayIndexIfNeeded() {
        guard !lastDoneDayKey.isEmpty else { return }
        guard lastDoneDayKey != todayKey else { return }

        if currentCompassionDayIndex <= lastCompletedCompassionDayIndex {
            currentCompassionDayIndex = lastCompletedCompassionDayIndex + 1
        }
    }

    @MainActor
    private func loadCompassionEntry() async {
        isLoading = true

        do {
            let entry = try await fetchCompassionEntry()

            if let entry {
                loadedEntry = entry
                loadError = nil
                print("COMPASSION loaded entry \(entry.id)")
            } else {
                loadedEntry = nil
                loadError = "No compassion entry found. Using fallback content."
            }
        } catch {
            loadedEntry = nil
            loadError = "Could not load compassion from database. Using fallback content."
            print("COMPASSION LOAD FAILED: \(error)")
        }

        isLoading = false
    }

    private func fetchCompassionEntry() async throws -> CompassionEntry? {
        guard let endpointURL = compassionStepsEndpointURL else {
            throw URLError(.badURL)
        }

        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "dayIndex", value: String(max(1, currentCompassionDayIndex)))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("COMPASSION HTTP \(http.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(CompassionStepsResponse.self, from: data)
        return decoded.item
    }

    private var compassionStepsEndpointURL: URL? {
        let keys = [
            "COMPASSION_STEPS_ENDPOINT",
            "CompassionStepsEndpoint"
        ]

        for key in keys {
            if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String {
                let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty, let url = URL(string: cleaned) {
                    return url
                }
            }
        }

        return nil
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compassion is not decoration. Thinking of others turns attention outward and lightens the burden of self-concern.")
                .foregroundStyle(.secondary)

            Text("Each day offers a new angle on cultivating compassion.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if isLoading {
                Text("Loading today’s compassion...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let loadError {
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if isUsingFallback {
                Text("Using fallback compassion content.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image("lotus")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                Text("Today")
                    .font(.subheadline.weight(.semibold))
            }

            Text(displayedEntry.theme)
                .font(.title3.weight(.semibold))

            Text(displayedEntry.meaning)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.88))

            if !displayedEntry.practices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayedEntry.practices, id: \.self) { line in
                        CompassionLine(text: line)
                    }
                }
                .padding(.top, 2)
            }

            Divider()
                .padding(.top, 2)

            Text(displayedEntry.teaching)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.88))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var doneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if alreadyDoneToday {
                Text("Today’s compassion is done.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                markDoneAndReturnHome()
            } label: {
                Text("Done today")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(compassionFill)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var footerGlyph: some View {
        HStack {
            Spacer()
            Image("lotus")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 108, height: 108)
            Spacer()
        }
        .padding(.top, -20)
        .padding(.bottom, 8)
    }

    private func markDoneAndReturnHome() {
        if !alreadyDoneToday {
            lastDoneDayKey = todayKey
            lastCompletedCompassionDayIndex = max(lastCompletedCompassionDayIndex, currentCompassionDayIndex)
        }

        flow.openProgressWithBeadAnimation()
        dismiss() // pop back to Home hub so Progress is visible
    }
}

private struct CompassionLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.88))

            Spacer(minLength: 0)
        }
    }
}
