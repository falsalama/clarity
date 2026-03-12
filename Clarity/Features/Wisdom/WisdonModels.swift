//WisdomModels.swift

import Foundation
import SwiftData

enum WisdomLane: String, Codable, CaseIterable, Sendable {
    case opening
    case analytical
    case debate

    var title: String {
        switch self {
        case .opening: return "Opening"
        case .analytical: return "Analytical"
        case .debate: return "Debate"
        }
    }

    var subtitle: String {
        switch self {
        case .opening:
            return "Accessible but serious contemplative inquiry."
        case .analytical:
            return "More precise and layered philosophical reasoning."
        case .debate:
            return "Full logical pressure and contradiction-testing."
        }
    }
}

enum WisdomLensKind: String, Codable, CaseIterable, Sendable {
    case buddhist
    case philosophical
    case logical
    case modern
    case contemplativeDirection

    var title: String {
        switch self {
        case .buddhist: return "Buddhist reasoning"
        case .philosophical: return "Philosophical comparison"
        case .logical: return "Logical pressure test"
        case .modern: return "Modern perspective"
        case .contemplativeDirection: return "What this opens"
        }
    }
}

enum WisdomCaptureMode: String, Codable, CaseIterable, Sendable {
    case text
    case voice
}

struct WisdomQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let setID: String
    let lane: WisdomLane
    let questionText: String
    let promptText: String
    let sourceTheme: String
    let sortIndex: Int
    let isActive: Bool
}

struct WisdomLens: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let questionID: String
    let kind: WisdomLensKind
    let sourceTitle: String
    let body: String
    let sortIndex: Int
}

struct WisdomDailySet: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let sortIndex: Int
    let isActive: Bool

    let openingQuestion: WisdomQuestion
    let analyticalQuestion: WisdomQuestion
    let debateQuestion: WisdomQuestion

    let openingLenses: [WisdomLens]
    let analyticalLenses: [WisdomLens]
    let debateLenses: [WisdomLens]

    func question(for lane: WisdomLane) -> WisdomQuestion {
        switch lane {
        case .opening: return openingQuestion
        case .analytical: return analyticalQuestion
        case .debate: return debateQuestion
        }
    }

    func lenses(for lane: WisdomLane) -> [WisdomLens] {
        switch lane {
        case .opening: return openingLenses.sorted { $0.sortIndex < $1.sortIndex }
        case .analytical: return analyticalLenses.sorted { $0.sortIndex < $1.sortIndex }
        case .debate: return debateLenses.sorted { $0.sortIndex < $1.sortIndex }
        }
    }
}

@Model
final class WisdomProgramStateEntity {
    var id: String
    var currentSetIndex: Int
    var pendingAdvanceDayKey: String?
    var updatedAt: Date

    init(
        id: String = "singleton",
        currentSetIndex: Int = 0,
        pendingAdvanceDayKey: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.currentSetIndex = currentSetIndex
        self.pendingAdvanceDayKey = pendingAdvanceDayKey
        self.updatedAt = updatedAt
    }
}

@Model
final class WisdomResponseEntity {
    var id: String

    var dayKey: String
    var completedAt: Date

    var setID: String
    var setTitle: String

    var questionID: String
    var laneRaw: String
    var questionText: String
    var promptText: String
    var sourceTheme: String

    var captureModeRaw: String

    var answerText: String
    var typedText: String?
    var rawTranscript: String?
    var redactedTranscript: String?

    // Future shared plumbing hooks
    var walJSON: String?
    var traceJSON: String?

    init(
        id: String = UUID().uuidString,
        dayKey: String,
        completedAt: Date = Date(),
        setID: String,
        setTitle: String,
        questionID: String,
        laneRaw: String,
        questionText: String,
        promptText: String,
        sourceTheme: String,
        captureModeRaw: String = WisdomCaptureMode.text.rawValue,
        answerText: String,
        typedText: String? = nil,
        rawTranscript: String? = nil,
        redactedTranscript: String? = nil,
        walJSON: String? = nil,
        traceJSON: String? = nil
    ) {
        self.id = id
        self.dayKey = dayKey
        self.completedAt = completedAt
        self.setID = setID
        self.setTitle = setTitle
        self.questionID = questionID
        self.laneRaw = laneRaw
        self.questionText = questionText
        self.promptText = promptText
        self.sourceTheme = sourceTheme
        self.captureModeRaw = captureModeRaw
        self.answerText = answerText
        self.typedText = typedText
        self.rawTranscript = rawTranscript
        self.redactedTranscript = redactedTranscript
        self.walJSON = walJSON
        self.traceJSON = traceJSON
    }

    var lane: WisdomLane {
        WisdomLane(rawValue: laneRaw) ?? .opening
    }

    var captureMode: WisdomCaptureMode {
        WisdomCaptureMode(rawValue: captureModeRaw) ?? .text
    }
}

enum WisdomSeedData {
    static let dailySets: [WisdomDailySet] = [
        WisdomDailySet(
            id: "wisdom_set_001",
            title: "Identity and appearance",
            sortIndex: 0,
            isActive: true,

            openingQuestion: WisdomQuestion(
                id: "wisdom_set_001_opening",
                setID: "wisdom_set_001",
                lane: .opening,
                questionText: "If the self cannot be found as one fixed thing, what exactly is being defended when you feel threatened?",
                promptText: "Be precise. Name what seems to be at risk without defaulting to vague words like ego or identity.",
                sourceTheme: "selflessness",
                sortIndex: 0,
                isActive: true
            ),
            analyticalQuestion: WisdomQuestion(
                id: "wisdom_set_001_analytical",
                setID: "wisdom_set_001",
                lane: .analytical,
                questionText: "If a person is neither identical to the body nor completely separate from it, in what sense does the person exist?",
                promptText: "Work carefully through identity, dependence, designation, and continuity.",
                sourceTheme: "personhood",
                sortIndex: 1,
                isActive: true
            ),
            debateQuestion: WisdomQuestion(
                id: "wisdom_set_001_debate",
                setID: "wisdom_set_001",
                lane: .debate,
                questionText: "If the self existed intrinsically, would it have to be one with the aggregates or different from them - and what contradiction follows in each case?",
                promptText: "Test both positions fully. Do not skip the consequences.",
                sourceTheme: "madhyamaka",
                sortIndex: 2,
                isActive: true
            ),

            openingLenses: [
                WisdomLens(
                    id: "wisdom_set_001_opening_buddhist",
                    questionID: "wisdom_set_001_opening",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "A Buddhist reading asks whether what is defended can actually be found as a single owner, centre, or essence. Usually what feels threatened is a constructed positioning made from memory, feeling, role, and anticipation rather than an intrinsically existing self.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_001_opening_philosophical",
                    questionID: "wisdom_set_001_opening",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "Philosophically, the issue is whether identity is substance, continuity, narrative, social recognition, or functional organisation. Different schools protect different things under the same word self.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_001_opening_logical",
                    questionID: "wisdom_set_001_opening",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "The question forces a distinction between what is felt, what is inferred, and what is actually established. Strong defensiveness does not prove that a solid self is present.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_001_opening_modern",
                    questionID: "wisdom_set_001_opening",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Contemporary cognitive science often treats selfhood as constructed, distributed, and model-based. That supports the possibility that what is being defended is a dynamically maintained representation rather than a fixed entity.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_001_opening_direction",
                    questionID: "wisdom_set_001_opening",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "When the defended self is examined rather than assumed, the emotional force around it can loosen. Analysis becomes a way into spaciousness rather than an argument about doctrine.",
                    sortIndex: 4
                )
            ],
            analyticalLenses: [
                WisdomLens(
                    id: "wisdom_set_001_analytical_buddhist",
                    questionID: "wisdom_set_001_analytical",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "The classical Buddhist move is to reject both strict identity and total separateness. A person exists conventionally, dependently designated in relation to body, mind, continuity, naming, and function, without being findable as an independent core.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_001_analytical_philosophical",
                    questionID: "wisdom_set_001_analytical",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "This parallels long-standing debates about personal identity: substance views, bundle theories, continuity theories, and narrative accounts each preserve something while giving up something else.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_001_analytical_logical",
                    questionID: "wisdom_set_001_analytical",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "If the person were identical with the body, any bodily change would destroy the person. If the person were wholly separate, relation and interaction become difficult to explain. Dependent designation avoids both extremes.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_001_analytical_modern",
                    questionID: "wisdom_set_001_analytical",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Modern thought often describes persons as emergent patterns: real enough for function and responsibility, but not self-grounded in the strong metaphysical sense.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_001_analytical_direction",
                    questionID: "wisdom_set_001_analytical",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "Seeing conventional existence clearly without collapsing into either essence or nihilism is a direct training in the middle way.",
                    sortIndex: 4
                )
            ],
            debateLenses: [
                WisdomLens(
                    id: "wisdom_set_001_debate_buddhist",
                    questionID: "wisdom_set_001_debate",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "This is a classic Madhyamaka-style analysis. If self were intrinsically one with the aggregates, it would share all their plurality and instability. If different from them, it could not be located, known, or causally involved with lived experience.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_001_debate_philosophical",
                    questionID: "wisdom_set_001_debate",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "The broader issue is whether identity can survive strict scrutiny under composition, change, and dependence. Many traditions find that ordinary self-language works pragmatically while failing under ultimate analysis.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_001_debate_logical",
                    questionID: "wisdom_set_001_debate",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "The task is not to win rhetorically but to expose contradiction. If one horn collapses into multiplicity and the other into irrelevance, the intrinsic self thesis loses coherence.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_001_debate_modern",
                    questionID: "wisdom_set_001_debate",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Systems theory and cognitive science also push away from a self-grounding entity toward process, relation, and pattern. That does not by itself prove emptiness, but it weakens naive essentialism.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_001_debate_direction",
                    questionID: "wisdom_set_001_debate",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "When intrinsic identity fails under analysis, what remains is not blank nothingness but a lighter, more workable mode of appearance.",
                    sortIndex: 4
                )
            ]
        ),

        WisdomDailySet(
            id: "wisdom_set_002",
            title: "Dependence and reality",
            sortIndex: 1,
            isActive: true,

            openingQuestion: WisdomQuestion(
                id: "wisdom_set_002_opening",
                setID: "wisdom_set_002",
                lane: .opening,
                questionText: "If something depends on causes and conditions, does that make it less real or more accurately understood?",
                promptText: "Do not answer with slogans. Explain what kind of reality remains once independence is removed.",
                sourceTheme: "dependent-arising",
                sortIndex: 0,
                isActive: true
            ),
            analyticalQuestion: WisdomQuestion(
                id: "wisdom_set_002_analytical",
                setID: "wisdom_set_002",
                lane: .analytical,
                questionText: "Does dependence undermine existence, or does it undermine only the fantasy of self-grounded existence?",
                promptText: "Separate conventional functioning from intrinsic status.",
                sourceTheme: "emptiness-and-appearance",
                sortIndex: 1,
                isActive: true
            ),
            debateQuestion: WisdomQuestion(
                id: "wisdom_set_002_debate",
                setID: "wisdom_set_002",
                lane: .debate,
                questionText: "If a thing existed from its own side, how could it depend on parts, causes, naming, or observation without contradiction?",
                promptText: "Test each mode of dependence carefully against intrinsic existence.",
                sourceTheme: "svabhava-critique",
                sortIndex: 2,
                isActive: true
            ),

            openingLenses: [
                WisdomLens(
                    id: "wisdom_set_002_opening_buddhist",
                    questionID: "wisdom_set_002_opening",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "From a Buddhist perspective, dependence does not weaken reality; it clarifies it. Things function, appear, and matter precisely because they arise relationally, not because they stand alone.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_002_opening_philosophical",
                    questionID: "wisdom_set_002_opening",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "Metaphysically, the issue is whether independence is a requirement for reality or merely a particular kind of idealised being. Many relational ontologies reject the assumption that dependence equals deficiency.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_002_opening_logical",
                    questionID: "wisdom_set_002_opening",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "The hidden premise is often: ‘If not self-existing, then unreal.’ But that is a false binary. Something may be dependent and still operationally real.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_002_opening_modern",
                    questionID: "wisdom_set_002_opening",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Modern science routinely understands phenomena through networks, relations, fields, systems, and emergent organisation. Dependence is often the way reality becomes intelligible.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_002_opening_direction",
                    questionID: "wisdom_set_002_opening",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "When dependence is seen as clarity rather than weakness, grasping at fixed certainty begins to soften.",
                    sortIndex: 4
                )
            ],
            analyticalLenses: [
                WisdomLens(
                    id: "wisdom_set_002_analytical_buddhist",
                    questionID: "wisdom_set_002_analytical",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "Emptiness undermines intrinsic existence, not conventional existence. Things still arise, function, and matter, but not as self-grounded units existing from their own side.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_002_analytical_philosophical",
                    questionID: "wisdom_set_002_analytical",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "This resembles distinctions between strong metaphysical substance and weaker, relational, processual, or pragmatic forms of being. The target is not existence itself, but a certain inflated picture of what existence must be.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_002_analytical_logical",
                    questionID: "wisdom_set_002_analytical",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "If a thing requires conditions, then its identity cannot be wholly self-grounded. But it does not follow that it vanishes into nonexistence. That inference is too strong.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_002_analytical_modern",
                    questionID: "wisdom_set_002_analytical",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Physics, biology, and cognitive science often replace atomistic self-standing entities with dynamic interdependence. The shift is away from essence, not away from meaningful appearance.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_002_analytical_direction",
                    questionID: "wisdom_set_002_analytical",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "Once existence is no longer imagined as self-grounded, the middle way becomes easier to sense directly.",
                    sortIndex: 4
                )
            ],
            debateLenses: [
                WisdomLens(
                    id: "wisdom_set_002_debate_buddhist",
                    questionID: "wisdom_set_002_debate",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "Intrinsic existence and dependence work against one another. If something truly existed from its own side, it would not need causes, parts, conceptual imputation, or relational conditions.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_002_debate_philosophical",
                    questionID: "wisdom_set_002_debate",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "The debate turns on whether strong independence is coherent at all once composition, causation, and cognition are taken seriously. Many contemporary frameworks find it increasingly hard to sustain.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_002_debate_logical",
                    questionID: "wisdom_set_002_debate",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "A truly intrinsic entity would have to remain exactly what it is regardless of condition. But then causal interaction and knowability become difficult to explain.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_002_debate_modern",
                    questionID: "wisdom_set_002_debate",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Modern scientific models often rely on interaction, measurement, relation, and emergent structure, which all sit awkwardly with the idea of totally self-standing intrinsic entities.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_002_debate_direction",
                    questionID: "wisdom_set_002_debate",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "The collapse of intrinsic solidity need not feel like loss. It can feel like release into a world that functions without needing fixed cores.",
                    sortIndex: 4
                )
            ]
        ),

        WisdomDailySet(
            id: "wisdom_set_003",
            title: "Awareness and knowing",
            sortIndex: 2,
            isActive: true,

            openingQuestion: WisdomQuestion(
                id: "wisdom_set_003_opening",
                setID: "wisdom_set_003",
                lane: .opening,
                questionText: "When you say you are aware, what exactly are you referring to?",
                promptText: "Distinguish direct experience, concept, and assumption.",
                sourceTheme: "awareness",
                sortIndex: 0,
                isActive: true
            ),
            analyticalQuestion: WisdomQuestion(
                id: "wisdom_set_003_analytical",
                setID: "wisdom_set_003",
                lane: .analytical,
                questionText: "Is awareness something that exists as an independent observer, or is that itself a conceptual construction laid over experience?",
                promptText: "Examine observer, observed, and the relation between them.",
                sourceTheme: "subject-object",
                sortIndex: 1,
                isActive: true
            ),
            debateQuestion: WisdomQuestion(
                id: "wisdom_set_003_debate",
                setID: "wisdom_set_003",
                lane: .debate,
                questionText: "If awareness existed intrinsically, would it have to be singular, multiple, changing, or unchanging - and what problem arises in each case?",
                promptText: "Push the analysis until the options show their instability.",
                sourceTheme: "mind-analysis",
                sortIndex: 2,
                isActive: true
            ),

            openingLenses: [
                WisdomLens(
                    id: "wisdom_set_003_opening_buddhist",
                    questionID: "wisdom_set_003_opening",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "The Buddhist move is often to distinguish immediate knowing from the stories layered onto it. Awareness may be directly obvious as experience, while many claims about what it is remain inferred.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_003_opening_philosophical",
                    questionID: "wisdom_set_003_opening",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "Philosophy asks whether awareness is substance, property, process, relation, or irreducible fact. The word seems simple while the metaphysics beneath it are not.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_003_opening_logical",
                    questionID: "wisdom_set_003_opening",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "The statement ‘I am aware’ does not by itself settle what awareness is. It may name a fact of experience while leaving ontology open.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_003_opening_modern",
                    questionID: "wisdom_set_003_opening",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Neuroscience and philosophy of mind both show how difficult it is to move from reports of experience to definitive claims about the metaphysical nature of consciousness.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_003_opening_direction",
                    questionID: "wisdom_set_003_opening",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "Precision here can quiet both naive certainty and vague mystification. The question becomes a support for stable seeing.",
                    sortIndex: 4
                )
            ],
            analyticalLenses: [
                WisdomLens(
                    id: "wisdom_set_003_analytical_buddhist",
                    questionID: "wisdom_set_003_analytical",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "Buddhist analysis often challenges the instinct to posit a hidden witness standing behind experience. The observer may itself be another dependently designated appearance rather than a separate knower-substance.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_003_analytical_philosophical",
                    questionID: "wisdom_set_003_analytical",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "This parallels debates over subjectivity, self-presence, higher-order awareness, and whether the observer is fundamental or constructed through reflective cognition.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_003_analytical_logical",
                    questionID: "wisdom_set_003_analytical",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "If an observer is posited to explain knowing, one must then explain how that observer is known. The model can regress unless carefully handled.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_003_analytical_modern",
                    questionID: "wisdom_set_003_analytical",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Modern models often treat subject-object structure as dynamically generated rather than metaphysically fixed. That is compatible with questioning the solidity of an independent inner watcher.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_003_analytical_direction",
                    questionID: "wisdom_set_003_analytical",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "As the imagined observer relaxes, knowing can feel less split. Thought becomes less of a cage and more of a clarifying instrument.",
                    sortIndex: 4
                )
            ],
            debateLenses: [
                WisdomLens(
                    id: "wisdom_set_003_debate_buddhist",
                    questionID: "wisdom_set_003_debate",
                    kind: .buddhist,
                    sourceTitle: "Buddhist reasoning",
                    body: "If awareness were intrinsically singular, plurality of cognitions becomes difficult. If multiple, unity is lost. If changing, fixed identity fails. If unchanging, relation to new objects becomes difficult. The point is not to deny knowing, but to deny intrinsic status.",
                    sortIndex: 0
                ),
                WisdomLens(
                    id: "wisdom_set_003_debate_philosophical",
                    questionID: "wisdom_set_003_debate",
                    kind: .philosophical,
                    sourceTitle: "Philosophical comparison",
                    body: "This resembles stronger metaphysical pressures in philosophy of mind: whether consciousness is simple, composite, temporally continuous, or self-identical across change.",
                    sortIndex: 1
                ),
                WisdomLens(
                    id: "wisdom_set_003_debate_logical",
                    questionID: "wisdom_set_003_debate",
                    kind: .logical,
                    sourceTitle: "Logical pressure test",
                    body: "Each proposed mode carries a cost. The exercise is to show that intrinsic awareness claims often smuggle in incompatible requirements.",
                    sortIndex: 2
                ),
                WisdomLens(
                    id: "wisdom_set_003_debate_modern",
                    questionID: "wisdom_set_003_debate",
                    kind: .modern,
                    sourceTitle: "Modern perspective",
                    body: "Contemporary work on distributed processing, temporal integration, and predictive models complicates the picture of awareness as a self-existing simple entity.",
                    sortIndex: 3
                ),
                WisdomLens(
                    id: "wisdom_set_003_debate_direction",
                    questionID: "wisdom_set_003_debate",
                    kind: .contemplativeDirection,
                    sourceTitle: "What this opens",
                    body: "When awareness is no longer reified, experience can remain vivid without needing a metaphysical centre to hold it together.",
                    sortIndex: 4
                )
            ]
        )
    ]

    static var activeDailySets: [WisdomDailySet] {
        dailySets
            .filter { $0.isActive }
            .sorted { $0.sortIndex < $1.sortIndex }
    }
}
