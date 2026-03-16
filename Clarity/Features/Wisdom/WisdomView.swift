import SwiftUI
import SwiftData
import UIKit

struct WisdomView: View {
    @State private var selectedPrompt: WisdomPrompt?
    @State private var loadedPrompts: [WisdomPrompt] = []

    @Query(
        sort: [SortDescriptor(\WisdomResponseEntity.completedAt, order: .reverse)]
    )
    private var responses: [WisdomResponseEntity]

    // TEMP fallback until Supabase fetch is wired
    private let fallbackPrompts: [WisdomPrompt] = [
        .init(
            id: "wisdom_q_001",
            category: "Identity",
            question: "If a self cannot be found, what exactly is being defended?",
            prompt: "Be precise. Do not answer with a slogan."
        ),
        .init(
            id: "wisdom_q_002",
            category: "Emptiness",
            question: "Can something appear clearly and still lack intrinsic existence?",
            prompt: "Separate appearance, function, and inherent reality."
        ),
        .init(
            id: "wisdom_q_003",
            category: "Language",
            question: "When you name an experience, what is added that was not there before?",
            prompt: "Distinguish direct experience from conceptual overlay."
        )
    ]

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var displayedPrompts: [WisdomPrompt] {
        let published = loadedPrompts
            .filter { $0.isPublished }
            .sorted {
                if $0.programmeSlug == $1.programmeSlug {
                    return $0.stepIndex < $1.stepIndex
                }
                return $0.programmeSlug < $1.programmeSlug
            }

        return published.isEmpty ? fallbackPrompts : published
    }

    private var todayKey: String {
        let cal = Calendar.current
        let d = cal.startOfDay(for: Date())
        let y = cal.component(.year, from: d)
        let m = cal.component(.month, from: d)
        let day = cal.component(.day, from: d)
        return String(format: "%04d-%02d-%02d", y, m, day)
    }

    private func response(for prompt: WisdomPrompt) -> WisdomResponseEntity? {
        responses.first(where: { $0.dayKey == todayKey && $0.questionID == prompt.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                todayHeader
                questionCards
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
        .navigationTitle("Wisdom")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPrompt) { prompt in
            WisdomPromptCaptureView(prompt: prompt)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image("dorje2")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(wisdomFill)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Logic and insight training")
                        .font(.title3.weight(.semibold))
                }

                Spacer()
            }

            Text("Choose one question each day and answer in your own words.")
                .foregroundStyle(.secondary)

            Text("This is philosophical and contemplative training for loosening fixation through reasoning, perspective, and analytical inquiry.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var todayHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s questions")
                .font(.headline)

            Text("Choose 1 of the following questions.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var questionCards: some View {
        VStack(spacing: 12) {
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
                WisdomCompareView(response: response)
            }
        }
    }

    private var categoryChip: some View {
        HStack(spacing: 8) {
            Image("dorje2")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(accent)

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
    }

    var category: String { title }
    var prompt: String { "" }
}
