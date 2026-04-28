import SwiftUI
import SwiftData
import UIKit

struct WisdomView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedPrompt: WisdomPrompt?
    @State private var loadedPrompts: [WisdomPrompt] = []
    @State private var loadError: String?
    @State private var isLoadingPrompts = true
    @State private var completedPromptForNavigation: WisdomPrompt?
    @State private var contentReady = false
    @State private var lastLoadedDayKey = ""
    
    @AppStorage("wisdom_current_day_index")
    private var currentWisdomDayIndex: Int = 1

    @AppStorage("wisdom_last_completed_day_index")
    private var lastCompletedWisdomDayIndex: Int = 0

    @AppStorage("wisdom_last_done_day_key")
    private var lastDoneDayKey: String = ""

    @Query(
        sort: [SortDescriptor(\WisdomResponseEntity.completedAt, order: .reverse)]
    )
    private var responses: [WisdomResponseEntity]

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var todayKey: String {
        Date().dayKey()
    }

    private var isDoneToday: Bool {
        lastDoneDayKey == todayKey
    }

    private var displayedPrompts: [WisdomPrompt] {
        loadedPrompts
            .filter { $0.isPublished }
            .sorted {
                if let lhsDay = $0.dayIndex, let rhsDay = $1.dayIndex, lhsDay != rhsDay {
                    return lhsDay < rhsDay
                }
                if let lhsSlot = $0.slotIndex, let rhsSlot = $1.slotIndex, lhsSlot != rhsSlot {
                    return lhsSlot < rhsSlot
                }
                if $0.programmeSlug == $1.programmeSlug {
                    return $0.stepIndex < $1.stepIndex
                }
                return $0.programmeSlug < $1.programmeSlug
            }
    }

    private func response(for prompt: WisdomPrompt) -> WisdomResponseEntity? {
        responses.first(where: { $0.questionID == prompt.id && $0.dayKey == todayKey })
    }

    private var latestTodayResponse: WisdomResponseEntity? {
        responses.first(where: { $0.dayKey == todayKey })
    }

    private var latestTodayPrompt: WisdomPrompt? {
        guard let response = latestTodayResponse else { return nil }
        return displayedPrompts.first(where: { $0.id == response.questionID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let loadError, !isLoadingPrompts {
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if isDoneToday {
                    doneTodayCard
                        .opacity(contentReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.32), value: contentReady)
                } else {
                    todayHeader
                    questionCards
                        .opacity(contentReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.32), value: contentReady)
                }

                HStack {
                    Spacer()
                    Image("dorje2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                        .opacity(0.9)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .padding(16)
        }
        .background {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                WisdomBackgroundWaterView()
            }
            .ignoresSafeArea()
        }
        .overlay {
            if isLoadingPrompts {
                ProgressView()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Wisdom")
                        .font(.headline)

                    Text("logic and analytical training")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationDestination(item: $selectedPrompt) { prompt in
            WisdomPromptCaptureView(prompt: prompt)
        }
        .navigationDestination(item: $completedPromptForNavigation) { prompt in
            if let response = latestTodayResponse {
                WisdomCompareView(response: response, prompt: prompt, backGoesHome: true)
            }
        }
        .task(id: currentWisdomDayIndex) {
            syncDayIndexIfNeeded()
            await loadWisdomPrompts()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            guard lastLoadedDayKey != todayKey else { return }
            Task {
                syncDayIndexIfNeeded()
                await loadWisdomPrompts()
            }
        }
    }

    private func syncDayIndexIfNeeded() {
        guard !lastDoneDayKey.isEmpty else { return }
        guard lastDoneDayKey != todayKey else { return }

        if currentWisdomDayIndex <= lastCompletedWisdomDayIndex {
            currentWisdomDayIndex = lastCompletedWisdomDayIndex + 1
        }
    }

    @MainActor
    private func loadWisdomPrompts() async {
        isLoadingPrompts = true
        contentReady = false
        loadedPrompts = []
        loadError = nil

        do {
            let prompts = try await fetchWisdomPrompts()

            if prompts.isEmpty {
                loadedPrompts = []
                loadError = "No wisdom entries found."
            } else {
                loadedPrompts = prompts
                loadError = nil
#if DEBUG
                print("WISDOM loaded \(prompts.count) prompts from edge function")
#endif
            }
        } catch {
            loadedPrompts = []
            loadError = "Could not load wisdom from database."
#if DEBUG
            print("WISDOM LOAD FAILED: \(error)")
#endif
        }

        isLoadingPrompts = false
        lastLoadedDayKey = todayKey
        withAnimation(.easeOut(duration: 0.32)) {
            contentReady = true
        }
    }

    private func fetchWisdomPrompts() async throws -> [WisdomPrompt] {
        guard let endpointURL = wisdomStepsEndpointURL else {
            throw URLError(.badURL)
        }

        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "dayIndex", value: String(max(1, currentWisdomDayIndex)))
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
#if DEBUG
            print("WISDOM HTTP \(http.statusCode): \(body)")
#endif
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(WisdomStepsResponse.self, from: data)
#if DEBUG
        print("WISDOM dayIndex =", decoded.dayIndex, "items =", decoded.items.count)
#endif
        return decoded.items
    }

    private var wisdomStepsEndpointURL: URL? {
        let keys = [
            "WISDOM_STEPS_ENDPOINT",
            "WisdomStepsEndpoint"
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

    private var todayHeader: some View {
        Text("Today’s questions")
            .font(.headline)
    }

    private var doneTodayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today’s wisdom is complete.")
                .font(.headline)

            if let response = latestTodayResponse {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chosen question")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(response.questionText)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your answer")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(response.answerText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button {
                guard let prompt = latestTodayPrompt else { return }
                completedPromptForNavigation = prompt
            } label: {
                Text("Open completed view")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(wisdomFill)
            .disabled(latestTodayPrompt == nil || latestTodayResponse == nil)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    private var questionCards: some View {
        VStack(spacing: 12) {
            if !isLoadingPrompts {
                if displayedPrompts.isEmpty {
                    Text("No wisdom questions available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(displayedPrompts) { prompt in
                        Button {
                            selectedPrompt = prompt
                        } label: {
                            WisdomQuestionCard(
                                prompt: prompt,
                                response: response(for: prompt),
                                accent: wisdomFill
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct WisdomQuestionCard: View {
    let prompt: WisdomPrompt
    let response: WisdomResponseEntity?
    let accent: Color

    @State private var showCompare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                categoryChip
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(accent.opacity(0.75))
            }

            Text(prompt.question)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let response {
                Divider()

                Text("Your answer")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(response.answerText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showCompare = true
                } label: {
                    Text("Compare views")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .navigationDestination(isPresented: $showCompare) {
            if let response {
                WisdomCompareView(response: response, prompt: prompt, backGoesHome: false)
            }
        }
    }

    private var categoryChip: some View {
        HStack(spacing: 8) {
            Image("dorje2")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)

            Text(prompt.category)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(accent)
        }
    }
}

struct WisdomPrompt: Identifiable, Hashable, Codable {
    let id: String
    let programmeSlug: String
    let stepIndex: Int
    let title: String
    let question: String
    let buddhistView: String
    let philosophicalView: String
    let scientificView: String
    let isPublished: Bool
    let version: Int
    let dayIndex: Int?
    let slotIndex: Int?
    let lane: String?

    enum CodingKeys: String, CodingKey {
        case id
        case programmeSlug = "programme_slug"
        case stepIndex = "step_index"
        case title
        case question
        case buddhistView = "buddhist_view"
        case philosophicalView = "philosophical_view"
        case scientificView = "scientific_view"
        case isPublished = "is_published"
        case version
        case dayIndex = "day_index"
        case slotIndex = "slot_index"
        case lane
    }

    init(
        id: String,
        category: String,
        question: String,
        prompt: String
    ) {
        self.id = id
        self.programmeSlug = "core"
        self.stepIndex = 0
        self.title = category
        self.question = question
        self.buddhistView = ""
        self.philosophicalView = ""
        self.scientificView = ""
        self.isPublished = true
        self.version = 1
        self.dayIndex = nil
        self.slotIndex = nil
        self.lane = nil
    }

    var category: String { title }
    var prompt: String { "" }
}
