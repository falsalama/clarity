import Foundation
import SwiftData

enum WisdomSeed {
    static func seedIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<WisdomQuestionEntity>()
        let existing = try context.fetchCount(descriptor)

        guard existing == 0 else { return }

        for item in questions {
            context.insert(
                WisdomQuestionEntity(
                    text: item.text,
                    difficulty: item.difficulty,
                    category: item.category
                )
            )
        }

        try context.save()
    }

    static let questions: [(text: String, difficulty: Int, category: String)] = [
        // MARK: - Logic

        ("Is a label the same as the thing it describes?", 1, "logic"),
        ("If something is named, does that prove it exists in the way it seems to?", 1, "logic"),
        ("Can a concept ever fully contain the thing it points to?", 1, "logic"),
        ("If a thing depends on parts, where exactly is the thing itself?", 1, "logic"),
        ("If the parts are removed, what remains of the whole?", 1, "logic"),
        ("Does naming something make it more solid, or only easier to discuss?", 1, "logic"),
        ("Can two people use the same word while referring to different realities?", 1, "logic"),
        ("If a category has fuzzy edges, where does membership truly begin?", 2, "logic"),
        ("Is a boundary found in the thing, or imposed by thought?", 2, "logic"),
        ("If a definition keeps changing with context, what is being defined?", 2, "logic"),
        ("When does a collection become a single thing?", 2, "logic"),
        ("If a thing only exists in relation to other things, can it stand alone?", 2, "logic"),
        ("Can a cause be found apart from its conditions?", 2, "logic"),
        ("If an effect depends on many conditions, which one deserves the credit?", 2, "logic"),
        ("If something appears stable but is always changing, what exactly is stable?", 2, "logic"),
        ("Does consistency prove truth, or only internal order?", 2, "logic"),
        ("If a contradiction appears, is the concept wrong or the framing too narrow?", 3, "logic"),
        ("Can anything be established from its own side without relying on comparison?", 3, "logic"),
        ("If something cannot be found under analysis but still functions, what kind of existence is that?", 3, "logic"),
        ("Does useful convention require intrinsic reality?", 3, "logic"),

        // MARK: - Identity

        ("When you say 'I', what exactly are you referring to?", 1, "identity"),
        ("Is the self the body, the mind, the memory, or the story?", 1, "identity"),
        ("If your mood changes, has the self changed too?", 1, "identity"),
        ("Can a self be found apart from changing experience?", 1, "identity"),
        ("If the self is constant, why does it feel different across situations?", 1, "identity"),
        ("If the self is changing, what makes it seem continuous?", 1, "identity"),
        ("Who is the owner when you think 'my mind'?", 2, "identity"),
        ("Who is being defended when self-image is threatened?", 2, "identity"),
        ("If identity depends on memory, what happens when memory fails?", 2, "identity"),
        ("Are you the observer of thought, or another thought about observing?", 2, "identity"),
        ("If you cannot find the self directly, what keeps the sense of self alive?", 2, "identity"),
        ("Is personality discovered, built, or repeatedly rehearsed?", 2, "identity"),
        ("When a role ends, what remains that was not the role?", 2, "identity"),
        ("If you are not your thoughts, are you separate from them?", 3, "identity"),
        ("Can the one who is searching be found apart from the search?", 3, "identity"),
        ("If the self is relational, can it exist in isolation?", 3, "identity"),
        ("What is the difference between continuity and sameness?", 3, "identity"),
        ("If no core self can be found, what exactly is rebelling, craving, or fearing?", 3, "identity"),
        ("Does the feeling of being someone prove there is a fixed someone?", 3, "identity"),
        ("What is left of 'me' when all descriptions are set aside?", 3, "identity"),

        // MARK: - Perception

        ("Do you see the world, or a constructed version of it?", 1, "perception"),
        ("How much of perception is received, and how much is added?", 1, "perception"),
        ("If two people see the same event differently, where is the event itself?", 1, "perception"),
        ("Does attention reveal reality, or select from it?", 1, "perception"),
        ("When something feels obvious, is it true or just familiar?", 1, "perception"),
        ("How much of what you notice is shaped by expectation?", 1, "perception"),
        ("If perception is filtered, can raw experience ever be known?", 2, "perception"),
        ("Does emotion colour perception, or uncover something hidden?", 2, "perception"),
        ("Can you distinguish what is present from what is inferred?", 2, "perception"),
        ("How quickly does thought convert sensation into narrative?", 2, "perception"),
        ("If something is unnoticed, in what sense was it present for you?", 2, "perception"),
        ("Is clarity the removal of distortion, or wiser interpretation of it?", 2, "perception"),
        ("When perception changes, did reality change or only access to it?", 2, "perception"),
        ("Can perspective be widened without creating a new fixed view?", 3, "perception"),
        ("If all seeing is conditioned, what makes one view wiser than another?", 3, "perception"),
        ("Does seeing through illusion produce a truer world or a less grasped one?", 3, "perception"),
        ("Can appearance be empty without being false?", 3, "perception"),
        ("If something is vividly experienced but conceptually ungraspable, how should it be understood?", 3, "perception"),

        // MARK: - Causality

        ("Does one cause ever produce one effect by itself?", 1, "causality"),
        ("If conditions are missing, can a cause still function?", 1, "causality"),
        ("When many causes converge, which one matters most?", 1, "causality"),
        ("Can an effect appear without a network of support?", 1, "causality"),
        ("Is timing part of causation, or only sequence?", 1, "causality"),
        ("If a result depends on context, was the cause ever enough on its own?", 2, "causality"),
        ("Can a seed be called a tree, or only a condition for one?", 2, "causality"),
        ("If a cause changes while producing an effect, what exactly is causing what?", 2, "causality"),
        ("Does interdependence weaken causality or explain it more fully?", 2, "causality"),
        ("If every event depends on prior events, where does responsibility fit?", 2, "causality"),
        ("Can a beginning be found in a circular system of conditions?", 2, "causality"),
        ("If no independent cause can be found, how do effects still arise?", 3, "causality"),
        ("Does karma require a fixed self, or only continuity of conditions?", 3, "causality"),
        ("When does a condition become a cause worth naming?", 3, "causality"),
        ("Can something be both empty and causally effective?", 3, "causality"),

        // MARK: - Compassion

        ("What changes when another person's suffering is felt as real as your own?", 1, "compassion"),
        ("Is kindness weaker or stronger when it expects nothing back?", 1, "compassion"),
        ("Can compassion exist without agreement?", 1, "compassion"),
        ("What blocks compassion more: judgment, fear, or fatigue?", 1, "compassion"),
        ("Does seeing your own confusion help you understand others more clearly?", 1, "compassion"),
        ("Can boundaries and compassion strengthen each other?", 2, "compassion"),
        ("If someone causes harm from confusion, how should they be seen?", 2, "compassion"),
        ("When you reduce someone to a type, what gets lost?", 2, "compassion"),
        ("Can compassion remain steady without becoming sentimental?", 2, "compassion"),
        ("Is patience a form of intelligence as well as kindness?", 2, "compassion"),
        ("What happens to blame when conditions are seen more fully?", 2, "compassion"),
        ("Can deep understanding make forgiveness easier without excusing harm?", 3, "compassion"),
        ("If there is no fixed self, who is the enemy?", 3, "compassion"),
        ("How does emptiness change the meaning of care?", 3, "compassion"),
        ("Can wisdom without warmth ever be complete?", 3, "compassion"),

        // MARK: - Emptiness

        ("If a thing cannot be found under analysis, in what way does it exist?", 1, "emptiness"),
        ("Can something function perfectly well while lacking intrinsic nature?", 1, "emptiness"),
        ("Does emptiness mean nothing exists, or that nothing exists independently?", 1, "emptiness"),
        ("If things arise dependently, what does that imply about their essence?", 1, "emptiness"),
        ("Is emptiness a property of things, or the absence of what was imagined?", 2, "emptiness"),
        ("Can emptiness itself be turned into a fixed view?", 2, "emptiness"),
        ("If you grasp emptiness as a concept, what has been missed?", 2, "emptiness"),
        ("How can appearance and emptiness coexist without contradiction?", 2, "emptiness"),
        ("If nothing has own-being, why does the world still matter?", 2, "emptiness"),
        ("Does seeing emptiness reduce care, or free care from fixation?", 2, "emptiness"),
        ("Can emptiness be found as an object among objects?", 3, "emptiness"),
        ("If emptiness is also empty, what remains to be held?", 3, "emptiness"),
        ("How does reifying emptiness differ from understanding it?", 3, "emptiness"),
        ("What is liberated when intrinsic reality is not found?", 3, "emptiness"),
        ("If all positions collapse under analysis, what kind of wisdom remains?", 3, "emptiness"),

        // MARK: - Language

        ("Does language reveal reality or organise experience?", 1, "language"),
        ("What is gained and lost the moment something is named?", 1, "language"),
        ("Can a word ever match the fullness of direct experience?", 1, "language"),
        ("When a phrase feels precise, is reality clearer or just more neatly framed?", 1, "language"),
        ("How much of conflict begins with clashing meanings rather than clashing facts?", 2, "language"),
        ("Can silence communicate something language cannot?", 2, "language"),
        ("Does description stabilise experience or distort it?", 2, "language"),
        ("If language is conventional, what makes one description wiser than another?", 2, "language"),
        ("Can a teaching point beyond concepts while still using them?", 3, "language"),
        ("When is a pointer mistaken for the thing pointed to?", 3, "language"),

        // MARK: - Time / change

        ("Where is the present before thought divides it?", 1, "time"),
        ("Does change require a stable thing that changes?", 1, "time"),
        ("If the past only appears now as memory, what is its current status?", 1, "time"),
        ("If the future appears now as anticipation, where exactly is it?", 1, "time"),
        ("Can continuity be found outside of mental stitching?", 2, "time"),
        ("If every moment depends on the previous one, where does one moment end and the next begin?", 2, "time"),
        ("Does impermanence make things less meaningful or more vivid?", 2, "time"),
        ("If nothing stays, what makes practice cumulative?", 2, "time"),
        ("Can a moment be isolated from conditions and still be a moment?", 3, "time"),
        ("What exactly travels from moment to moment?", 3, "time")
    ]
}
