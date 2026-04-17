import SwiftUI

struct CompassionView: View {
    @EnvironmentObject private var flow: AppFlowRouter
    @Environment(\.scenePhase) private var scenePhase

    @State private var loadedEntry: CompassionEntry?
    @State private var loadError: String?
    @State private var isLoading = true
    @State private var contentReady = false
    @State private var lastLoadedDayKey = ""

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

    private var todayKey: String {
        Date().dayKey()
    }

    private var alreadyDoneToday: Bool {
        lastDoneDayKey == todayKey
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let loadError, !isLoading {
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if loadedEntry != nil {
                    dailyCard
                        .opacity(contentReady ? 1 : 0)
                        .animation(.easeOut(duration: 0.32), value: contentReady)
                } else if !isLoading && loadError == nil {
                    Text("No compassion contemplation available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }

                doneCard
                    .opacity(contentReady ? 1 : 0)
                    .animation(.easeOut(duration: 0.32), value: contentReady)
                footerGlyph
            }
            .padding(16)
        }
        .background {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
        }
        .overlay {
            if isLoading {
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
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            guard lastLoadedDayKey != todayKey else { return }
            Task {
                syncDayIndexIfNeeded()
                await loadCompassionEntry()
            }
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
        contentReady = false
        loadedEntry = nil
        loadError = nil

        do {
            let response = try await fetchCompassionEntry()
            let normalizedDayIndex = max(1, response.dayIndex)

            if normalizedDayIndex != currentCompassionDayIndex {
                currentCompassionDayIndex = normalizedDayIndex
            }

            if let entry = response.item {
                loadedEntry = entry
                loadError = nil
                print("COMPASSION dayIndex =", normalizedDayIndex, "item =", entry.id)
            } else {
                loadedEntry = nil
                loadError = "No compassion entry found."
                print("COMPASSION dayIndex =", normalizedDayIndex, "item = nil")
            }
        } catch {
            loadedEntry = nil
            loadError = "Could not load compassion from database."
            print("COMPASSION LOAD FAILED: \(error)")
        }

        isLoading = false
        lastLoadedDayKey = todayKey
        withAnimation(.easeOut(duration: 0.32)) {
            contentReady = true
        }
    }

    private func fetchCompassionEntry() async throws -> CompassionStepsResponse {
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
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        applySupabaseHeaders(to: &req)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("COMPASSION HTTP \(http.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CompassionStepsResponse.self, from: data)
    }

    private func applySupabaseHeaders(to req: inout URLRequest) {
        guard let anonKey = CloudTapConfig.supabaseAnonKey, !anonKey.isEmpty else { return }

        req.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let accessToken = AppServices.supabaseAccessToken, !accessToken.isEmpty {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("COMPASSION using user access token")
        } else {
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            print("COMPASSION using anon key")
        }
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

    private var dailyCard: some View {
        guard let entry = loadedEntry else {
            return AnyView(EmptyView())
        }

        return AnyView(
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

            Text(entry.theme)
                .font(.title3.weight(.semibold))

            Text(entry.meaning)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.88))

            if !entry.practices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entry.practices, id: \.self) { line in
                        CompassionLine(text: line)
                    }
                }
                .padding(.top, 2)
            }

            Divider()
                .padding(.top, 2)

            Text(entry.teaching)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.88))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
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
            .disabled(alreadyDoneToday)
            .opacity(alreadyDoneToday ? 0.55 : 1)
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
        guard !alreadyDoneToday else { return }

        lastDoneDayKey = todayKey
        lastCompletedCompassionDayIndex = max(lastCompletedCompassionDayIndex, currentCompassionDayIndex)

        SparkleAudio.play()
        flow.openProgressWithBeadAnimation()
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
