import SwiftUI

struct TeachingsAudioView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let teachings = TeachingEntry.seed

    private var pageBackground: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.075, blue: 0.085),
                    Color(red: 0.095, green: 0.10, blue: 0.115),
                    Color(red: 0.08, green: 0.085, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.985, green: 0.985, blue: 0.98),
                Color(red: 0.972, green: 0.972, blue: 0.968),
                Color(red: 0.958, green: 0.962, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image("buttonteaching")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Teachings")
                        .font(.title3.weight(.semibold))

                    Text("A reading shelf of short contemplative teachings, practical advice, and lineage reflections.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(teachings) { teaching in
                        NavigationLink {
                            teachingDestination(for: teaching)
                        } label: {
                            TeachingCard(teaching: teaching)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background {
            pageBackground.ignoresSafeArea()
        }
        .navigationTitle("Teachings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    @ViewBuilder
    private func teachingDestination(for teaching: TeachingEntry) -> some View {
        if teaching.id == "training-the-monkey-mind" {
            TrainingMonkeyMindView()
        } else {
            TeachingDetailView(teaching: teaching)
        }
    }
}

private struct TeachingEntry: Identifiable {
    let id: String
    let title: String
    let teacher: String
    let lineage: String
    let sourceLabel: String
    let sourceURL: String?
    let cardSummary: String
    let overview: String
    let paragraphs: [String]
    let keyPoints: [String]
    let attributionNote: String

    static let seed: [TeachingEntry] = [
        TeachingEntry(
            id: "hhdl-mind-training",
            title: "Mind Training and Bodhichitta",
            teacher: "His Holiness the Dalai Lama",
            lineage: "Gelug / universal",
            sourceLabel: "dalailama.com",
            sourceURL: "https://www.dalailama.com/news/2020/a-short-teaching-on-mind-training",
            cardSummary: "A practical reminder that bodhichitta and emptiness have to be trained directly in the mind, not admired from a distance.",
            overview: "His Holiness places mind training on two rails at once: compassion for beings and insight into the lack of any fixed, independent self.",
            paragraphs: [
                "The emphasis is practical. Bodhichitta is not a decoration for practice but the atmosphere in which practice becomes real. Other beings are not interruptions to the path; they are the very field in which patience, humility, and compassion are trained.",
                "At the same time, the sense of a solid and self-existing 'I' has to be examined. The self functions, but it cannot be found in the way grasping assumes. This loosens the emotional rigidity that keeps suffering in place.",
                "Prayer and mantra still matter here, but only when the mind is actually engaged. Repetition without attention does not transform much. The point is to let the teaching work on the mindstream."
            ],
            keyPoints: [
                "Train compassion daily and in relation to real people.",
                "Investigate the self carefully rather than taking it for granted.",
                "Use prayer and mantra attentively, not mechanically."
            ],
            attributionNote: "In-app note based on a public teaching page."
        ),
        TeachingEntry(
            id: "karmapa-lojong",
            title: "Mind Training (Lojong)",
            teacher: "His Holiness the 17th Karmapa Ogyen Trinley Dorje",
            lineage: "Karma Kagyu",
            sourceLabel: "kagyuoffice.org",
            sourceURL: "https://kagyuoffice.org/the-karmapa-gives-an-extensive-teaching-on-mind-training/",
            cardSummary: "A clear explanation of lojong as a training in valuing others, lowering pride, and watching the mind in ordinary situations.",
            overview: "The Karmapa presents lojong as something exacting but usable: a way of meeting every relationship and every difficult mood as material for awakening mind.",
            paragraphs: [
                "He stresses that short mind-training texts are powerful precisely because they condense the point. Reading widely is not enough if the teachings never blend with the mind itself.",
                "Humility is not self-hatred. To place oneself lower than others in lojong means becoming teachable, less defended, and more open to qualities one does not yet embody.",
                "The decisive training is vigilance. As soon as affliction begins to rise, the practitioner learns to notice it early and turn it. That makes ordinary life the real practice field."
            ],
            keyPoints: [
                "Value beings more than self-importance.",
                "Use humility as an antidote to pride, not as self-denigration.",
                "Catch afflictions early through continuous watchfulness."
            ],
            attributionNote: "In-app note based on the official Karmapa teaching page."
        ),
        TeachingEntry(
            id: "yeshe-tsogyal-copper-coloured-mountain",
            title: "Aspiration for the Copper-Coloured Mountain",
            teacher: "Yeshe Tsogyal",
            lineage: "Nyingma",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/yeshe-tsogyal/zangdok-palri-prayer",
            cardSummary: "A devotional aspiration shaped by pure vision, refuge in the guru, and a resolve to continue practice in the pure realm of Guru Rinpoche.",
            overview: "This famous aspiration associated with Yeshe Tsogyal combines devotion, pure realm aspiration, and a strong sense that obstacles can be transformed through relationship to the guru and ḍākinīs.",
            paragraphs: [
                "The prayer begins by turning toward the sources of path and blessing: gurus, yidam deities, and ḍākinīs. The movement is relational rather than abstract.",
                "Its aspiration is not escapist. The pure realm is invoked as a field in which practice continues without interruption and awakening can ripen more completely.",
                "What gives the prayer its force is its emotional clarity: supplication, longing, courage, and confidence are all held together."
            ],
            keyPoints: [
                "Begin with devotion and connection to the sources of blessing.",
                "Treat aspiration as part of path, not fantasy.",
                "Let longing for awakening strengthen practice."
            ],
            attributionNote: "In-app note based on the public Lotsawa House page for Yeshe Tsogyal’s aspiration prayer."
        ),
        TeachingEntry(
            id: "guru-rinpoche-view-karma",
            title: "View Higher Than the Sky",
            teacher: "Guru Rinpoche",
            lineage: "Nyingma / Vajrayana",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/indian-masters/padmasambhava/view-is-higher",
            cardSummary: "A brief and cutting instruction: the highest view never cancels careful attention to karma.",
            overview: "This well-known saying attributed to Padmasambhava holds together two things that practitioners often split apart: vast view and exact ethical precision.",
            paragraphs: [
                "The warning is against spiritual inflation. One can speak about emptiness, pure perception, or non-duality while still being deeply careless in conduct.",
                "Guru Rinpoche’s point is that higher view should make one more exact with causality, not less. When the view becomes genuine, responsibility sharpens rather than dissolves.",
                "The saying stays alive because it cuts through a recurring confusion: mistaking lofty language for realisation."
            ],
            keyPoints: [
                "Do not use view to excuse carelessness.",
                "Karma still matters with absolute precision.",
                "Real realisation deepens ethical exactness."
            ],
            attributionNote: "In-app note based on a public quotation page at Lotsawa House."
        ),
        TeachingEntry(
            id: "bokar-rinpoche-mahamudra",
            title: "Mahamudrā in Ordinary Life",
            teacher: "His Eminence Bokar Rinpoche",
            lineage: "Karma Kagyu / Shangpa Kagyu",
            sourceLabel: "kcc.org",
            sourceURL: "https://kcc.org/home/retreats-events/mahamudra-program/",
            cardSummary: "A simple but exact Mahāmudrā emphasis: do not reject work and family, but integrate steady daily practice into ordinary life.",
            overview: "Bokar Rinpoche’s framing is strong because it refuses both romantic retreat-fantasy and diluted spirituality. Mahāmudrā remains profound, but the entry point is disciplined daily integration.",
            paragraphs: [
                "The instruction is refreshingly plain. Rather than waiting for perfect retreat conditions, the practitioner commits to a rhythm of daily practice that can actually be sustained.",
                "That does not trivialize Mahāmudrā. It makes it workable. Bokar Rinpoche’s emphasis is that deep practice matures through constancy, not through rare spiritual moods.",
                "This gives the teaching real value for lay life. Family, work, and responsibility are not automatically obstacles. The obstacle is inconsistency and the habit of postponing practice."
            ],
            keyPoints: [
                "Integrate daily meditation into ordinary life.",
                "Do not wait for ideal conditions to begin practicing seriously.",
                "Depth comes from steady continuity, not occasional intensity."
            ],
            attributionNote: "In-app note based on the public Mahamudra Program page describing Bokar Rinpoche’s guidance."
        ),
        TeachingEntry(
            id: "gyalwang-drukpa-rejoicing",
            title: "Rejoicing and Positive Relationship",
            teacher: "His Holiness the Gyalwang Drukpa",
            lineage: "Drukpa Kagyu",
            sourceLabel: "drukpa.org",
            sourceURL: "https://drukpa.org/journey/2519-rejoice-one-step-closer-to-your-nature",
            cardSummary: "A practical teaching that links rejoicing, understanding, and healthy relationship as part of the path rather than social decoration.",
            overview: "The Gyalwang Drukpa’s point is simple and sharp: relationships deteriorate not only because others are difficult, but because rejoicing and understanding are weak. Training those qualities is already part of awakening.",
            paragraphs: [
                "The teaching begins with ordinary life. Friendship, family, and Dharma relationship all change as emotions harden and appreciation drops away. Rejoicing is presented as an antidote to that contraction.",
                "This is not superficial positivity. To rejoice genuinely is to loosen envy, resentment, and habitual self-reference. That creates the space in which understanding can deepen.",
                "What makes the instruction strong is that it treats relationship as practice. The way one meets others is not separate from realisation; it reveals the state of one’s own mind."
            ],
            keyPoints: [
                "Rejoicing is a real practice, not a mood.",
                "Understanding grows when envy and resentment soften.",
                "Relationships reveal the quality of one’s path."
            ],
            attributionNote: "In-app note based on a public teaching article by His Holiness the Gyalwang Drukpa."
        ),
        TeachingEntry(
            id: "lama-zopa-compassion",
            title: "Compassion in Everyday Practice",
            teacher: "Lama Zopa Rinpoche",
            lineage: "Gelug / FPMT",
            sourceLabel: "fpmt.org",
            sourceURL: "https://fpmt.org/edu-news/advice/why-we-all-need-to-develop-compassion/",
            cardSummary: "A forceful reminder that compassion is not optional ornamentation but the basis of how Dharma practice should be motivated.",
            overview: "Lama Zopa brings everything back to motivation. Without compassion, even apparently spiritual activity drifts back toward self-concern.",
            paragraphs: [
                "The instruction is not to reserve compassion for people we already like. A practice that excludes strangers, critics, or difficult people is still narrow and unstable.",
                "Compassion is the basis for study, contemplation, service, and retreat. It is not one practice among others. It is meant to infuse all of them.",
                "This makes daily life the real testing ground. The question is not whether one has noble thoughts during formal practice, but whether one is training the heart throughout ordinary actions."
            ],
            keyPoints: [
                "Make compassion the motivation for all practice.",
                "Extend it beyond friends and agreeable people.",
                "Test it in ordinary life, not only on the cushion."
            ],
            attributionNote: "In-app note based on a public FPMT advice page."
        ),
        TeachingEntry(
            id: "namkhai-norbu-integration",
            title: "Meditation and Integration",
            teacher: "Chogyal Namkhai Norbu",
            lineage: "Dzogchen",
            sourceLabel: "melong.com",
            sourceURL: "https://melong.com/chogyal-namkhai-nobu-starting-the-evolution/",
            cardSummary: "A direct Dzogchen reminder that recognition has to be integrated into ordinary life, not preserved as a special meditative experience.",
            overview: "Namkhai Norbu emphasizes that the first glimpse of one's real condition is only the beginning. Practice matures through familiarity and integration.",
            paragraphs: [
                "Direct transmission or an initial recognition is important, but it is not yet stability. One has discovered the base, not completed the path.",
                "Meditation in this context is not a conceptual project. The instruction is to relax and become familiar with one's real condition, rather than manufacture a special state.",
                "The decisive point is integration. Awareness has to enter movement, speech, work, relationship, and ordinary circumstances. Otherwise insight remains compartmentalized."
            ],
            keyPoints: [
                "Initial recognition is only the first step.",
                "Meditation means familiarising oneself with real condition.",
                "Integration into daily life is what makes Dzogchen real."
            ],
            attributionNote: "In-app note based on a public excerpt from The Mirror."
        ),
        TeachingEntry(
            id: "garab-dorje-three-statements",
            title: "Three Statements that Strike the Vital Point",
            teacher: "Garab Dorje",
            lineage: "Dzogchen",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/topics/three-striking-statements/",
            cardSummary: "The classic Dzogchen triad: direct introduction, decisive certainty, and confidence in the self-liberation of arising thoughts.",
            overview: "Garab Dorje’s famous three statements are presented in the tradition as the distilled heart of Dzogchen transmission and practice.",
            paragraphs: [
                "The first statement points to direct introduction. Without recognizing awareness itself, Dzogchen remains a concept or aspiration rather than lived knowledge.",
                "The second statement concerns decisiveness. One has to settle the matter in one's own experience rather than continue searching for some other state elsewhere.",
                "The third statement is confidence in self-liberation. Thoughts do not need to be crushed or purified by force; they are recognized and released within awareness itself."
            ],
            keyPoints: [
                "Receive direct introduction to awareness itself.",
                "Resolve the path in immediate experience.",
                "Trust the self-liberation of arising thoughts."
            ],
            attributionNote: "In-app note based on the public Lotsawa House summary page for Garab Dorje’s three statements."
        ),
        TeachingEntry(
            id: "mandarava-prayer",
            title: "Princess Mandāravā’s Prayer",
            teacher: "Mandāravā",
            lineage: "Nyingma / Guru Rinpoche cycle",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/sangye-lingpa/prayer-of-princess-mandarava",
            cardSummary: "A striking prayer of devotion and impermanence: everything worldly falls away, and the guru becomes the only lasting refuge.",
            overview: "Mandāravā’s prayer is powerful because it joins beauty, devotion, and stark renunciation. Again and again it turns from what seems stable in life toward what can actually endure.",
            paragraphs: [
                "The prayer first praises Guru Rinpoche’s body, speech, and awakened compassion. It is devotional, but not vague. The devotion is tied to liberation from suffering, not to sentiment alone.",
                "Then the text turns through the familiar structures of life: homeland, house, wealth, family, reputation. Each is acknowledged and then stripped of permanence. On the day of death, none can be carried through.",
                "That is what gives the prayer its force. Mandāravā is not rejecting life in bitterness. She is clarifying where lasting refuge and inheritance really lie."
            ],
            keyPoints: [
                "Use devotion to clarify refuge, not to avoid reality.",
                "Contemplate death through the ordinary things one clings to.",
                "Let impermanence sharpen practice rather than darken it."
            ],
            attributionNote: "In-app note based on the public Lotsawa House page for Princess Mandāravā’s prayer."
        ),
        TeachingEntry(
            id: "pema-sal-nyingtik",
            title: "A Brief Life, a Lasting Transmission",
            teacher: "Princess Pema Sal",
            lineage: "Nyingma / Nyingtik",
            sourceLabel: "Rigpa Wiki",
            sourceURL: "https://www.rigpawiki.org/index.php?title=Pema_Sal",
            cardSummary: "A short but important lineage moment: Guru Rinpoche revives the young princess briefly, entrusts the Nyingtik, and a major transmission continues across lives.",
            overview: "Pema Sal’s story matters because it holds fragility and continuity together. Her life is brief, but the transmission entrusted to her carries forward through later revelation and rebirth.",
            paragraphs: [
                "The story is stark. The daughter of Trisong Detsen dies young, is briefly restored by Guru Rinpoche, receives the Nyingtik transmission, and then passes away again. The scene is small, but its implications are vast.",
                "What stands out is that the Dharma is not measured by the length of a life or the outward scale of an event. A brief opening can still carry enormous consequence.",
                "The later connection to Pema Ledreltsal and Longchen Rabjam gives the story its lineage weight. The teaching here is not only miraculous transmission, but the continuity of awakened intent across time."
            ],
            keyPoints: [
                "Do not measure spiritual significance by outward duration.",
                "Transmission can be hidden, carried, and revealed across lives.",
                "Fragility and continuity can coexist on the path."
            ],
            attributionNote: "In-app note based on the public Rigpa Wiki page for Princess Pema Sal."
        ),
        TeachingEntry(
            id: "machik-focused-relaxed",
            title: "Tightly Focused and Loosely Relaxed",
            teacher: "Machik Labdron",
            lineage: "Chöd",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/machik-labdron/tightly-focused-loosely-relaxed",
            cardSummary: "Two famous lines on balanced attention: alert but relaxed, steady without tightening.",
            overview: "Machik’s short saying is powerful because it gives a whole meditative orientation in a few words. It avoids both dullness and strain.",
            paragraphs: [
                "If attention is too loose, awareness becomes vague and sleepy. If it is too tight, the mind becomes brittle, effortful, and narrow.",
                "Machik’s instruction points to a middle poise: gathered enough to be awake, open enough to remain natural. This balance is not only for formal meditation but for difficult life situations too.",
                "The line is memorable because it names a subtle art. Many practitioners know one side of practice better than the other."
            ],
            keyPoints: [
                "Avoid both slackness and strain.",
                "Balanced attention is itself a crucial point of view.",
                "The same balance applies in meditation and daily life."
            ],
            attributionNote: "In-app note based on a public quotation page at Lotsawa House."
        ),
        TeachingEntry(
            id: "tilopa-ganges-mahamudra",
            title: "Ganges Mahamudra",
            teacher: "Tilopa",
            lineage: "Mahamudra",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/indian-masters/tilopa/ganges-mahamudra-instruction",
            cardSummary: "A foundational Mahamudra instruction to Naropa: relax mind in its natural state, cut striving, and let fixation dissolve.",
            overview: "Tilopa’s instruction is uncompromisingly direct. Mind does not need elaborate construction in order to be known; it needs release from distortion.",
            paragraphs: [
                "The text repeatedly points away from fabrication. Mahamudra is not reached by assembling concepts about the mind, but by allowing mind to rest without contrivance.",
                "Tilopa also cuts through fixation on scripture and systems when they become substitutes for direct knowing. Conceptual mastery is not itself realisation.",
                "Yet he is not vague or anti-practice. The instruction includes retreat, solitude, disenchantment with worldly absorption, and continuous familiarisation."
            ],
            keyPoints: [
                "Rest mind naturally rather than fabricating experience.",
                "Do not mistake conceptual mastery for realisation.",
                "Simplicity and retreat support direct knowing."
            ],
            attributionNote: "In-app note based on the public Lotsawa House translation of Tilopa’s Ganges Mahamudra."
        ),
        TeachingEntry(
            id: "naropa-eight-difficulties",
            title: "Eight Supreme Difficulties",
            teacher: "Naropa",
            lineage: "Kagyu / Mahamudra",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/indian-masters/naropa/eight-difficulties-song",
            cardSummary: "A spiritual song on how hard it is to secure the right outer and inner conditions for practice, and why they should not be wasted.",
            overview: "Naropa’s song is not pessimistic. It is clarifying. It names the rarity of authentic circumstances so that gratitude and diligence arise together.",
            paragraphs: [
                "Human birth, health, capable teachers, faithful students, supportive companions, and a good retreat place are all described as difficult to find. The point is not scarcity for its own sake, but the need for urgency.",
                "The song treats outer and inner conditions together. A good hermitage is not enough without trust, devotion, and steadiness; sincere intention is not enough without the right supports.",
                "Because these convergences are rare, one should stop acting as though there will always be more time."
            ],
            keyPoints: [
                "Authentic practice conditions are rare.",
                "Outer and inner supports both matter.",
                "Rarity should lead to urgency, not discouragement."
            ],
            attributionNote: "In-app note based on a public Lotsawa House translation of Nāropa’s spiritual song."
        ),
        TeachingEntry(
            id: "training-the-monkey-mind",
            title: "Training the Monkey Mind",
            teacher: "",
            lineage: "Shamatha / mind training",
            sourceLabel: "",
            sourceURL: nil,
            cardSummary: "A practical reading of the monk, elephant, and monkey image: attention is not forced into silence, but steadily educated.",
            overview: "This traditional image shows training as gradual familiarisation, not harsh control. The monk represents steady recollection, the monkey distraction, and the elephant the mind itself as it becomes more workable.",
            paragraphs: [
                "The monk, the elephant, and the monkey form a map of training the mind. The elephant represents mind itself: at first heavy, dark, and difficult to guide. The monkey represents distraction, restlessness, and the habit of chasing whatever pulls attention away. The monk is steady recollection, the quiet willingness to return again and again. As practice matures, the elephant gradually lightens, the monkey loses its hold, and the path becomes less about struggle and more about growing familiar with ease.",
                "This image is not teaching harsh control. It shows that mind can be trained without aggression. At first attention is scattered. Then it is gathered. Then it begins to rest. Along the way, agitation softens, dullness becomes more apparent, and awareness grows steadier, brighter, and more workable. What changes is not that thoughts are violently removed, but that they no longer dominate the whole field.",
                "This matters because calm is not the final goal. Shamatha prepares the ground. When the mind is less pulled around by impulse, there is more space, more clarity, and less belief in every passing movement. The point is not to become a perfect meditator. It is to discover that disturbance is not solid, attention can be educated, and openness is already nearer than it seems."
            ],
            keyPoints: [
                "The point is not to force the mind, but to keep returning.",
                "With practice, distraction loses some of its pull.",
                "Calm is groundwork, not the destination."
            ],
            attributionNote: ""
        ),
        TeachingEntry(
            id: "marpa-death-as-friend",
            title: "Taking Death as a Friend",
            teacher: "Marpa Lotsawa",
            lineage: "Kagyu",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/marpa-chokyi-lodro/nail-of-death-as-friend",
            cardSummary: "A hard-edged instruction on using death itself as part of the path rather than meeting it only as an enemy.",
            overview: "Marpa’s point is practical and severe: worldly beings fear death as annihilation, but a yogi can meet death as a final field of instruction and realisation.",
            paragraphs: [
                "The teaching assumes death cannot always be postponed or managed. At some point methods fail, and then the question becomes how one meets the process itself.",
                "Marpa reframes that moment. What ordinary mind experiences as defeat can become an opening when grounded in oral instruction and familiarity with mind.",
                "The deeper implication is that the path has to be trained now. One cannot improvise profound recognition in the bardo without present-life preparation."
            ],
            keyPoints: [
                "Death should be prepared for, not denied.",
                "What is feared can become part of the path.",
                "Bardo confidence depends on present training."
            ],
            attributionNote: "In-app note based on the public Lotsawa House translation of Marpa’s advice."
        ),
        TeachingEntry(
            id: "milarepa-horror-of-death",
            title: "In Horror of Death",
            teacher: "Milarepa",
            lineage: "Kagyu",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/milarepa/in-horror-of-death",
            cardSummary: "A brief and forceful Milarepa verse: fear of death drove him to retreat, and realisation dissolved that fear at the root.",
            overview: "This short verse is one of the clearest windows into Milarepa’s style. He does not romanticize retreat. Retreat is what he entered because death became undeniable.",
            paragraphs: [
                "The mountain is not presented as a scenic preference. It is the place to which he fled because ordinary life could no longer cover over impermanence.",
                "Repeatedly contemplating the uncertainty of death becomes the doorway to the deathless nature of mind. Fear is not merely soothed; it is outgrown through recognition.",
                "That makes the verse both fierce and encouraging. The same anxiety that unsettles life can become the very force that turns the mind toward truth."
            ],
            keyPoints: [
                "Use fear of death as fuel for practice.",
                "Retreat begins in existential honesty.",
                "Recognition of mind dissolves fear at the root."
            ],
            attributionNote: "In-app note based on a public quotation page at Lotsawa House."
        ),
        TeachingEntry(
            id: "ayang-rinpoche-phowa",
            title: "Phowa and Dying with Confidence",
            teacher: "His Eminence Ayang Rinpoche",
            lineage: "Drikung Kagyu / Nyingma",
            sourceLabel: "ayangrinpoche.org",
            sourceURL: "https://ayangrinpoche.org/phowa/",
            cardSummary: "A direct teaching on preparing for death through phowa: confidence comes from training, not from denial.",
            overview: "Ayang Rinpoche’s emphasis is precise and unsentimental. Death is certain, but panic is not inevitable. Practice can prepare the mind to meet death with direction and confidence.",
            paragraphs: [
                "Phowa is presented as a practical response to one of the deepest fears practitioners carry. It is not morbid, and it is not merely symbolic. It addresses the transition of death directly.",
                "What makes Ayang Rinpoche’s framing useful is its realism. If realisation is incomplete, one still needs methods. Phowa becomes a support rather than a grand claim about one's level of attainment.",
                "The teaching also cuts through avoidance. Death is not someone else’s problem, nor something to consider only when illness comes close. Preparing the mind now is itself a form of compassion and sanity."
            ],
            keyPoints: [
                "Train for death before the crisis arrives.",
                "Use method honestly when realisation is not yet stable.",
                "Let contemplation of death strengthen courage rather than fear."
            ],
            attributionNote: "In-app note based on the official Ayang Rinpoche page on phowa."
        ),
        TeachingEntry(
            id: "chandrakirti-compassion-middle-way",
            title: "Compassion at the Start of the Middle Way",
            teacher: "Chandrakirti",
            lineage: "Madhyamaka",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/indian-masters/chandrakirti/madhyamakavatara-quotations",
            cardSummary: "A reminder from the Madhyamakavatara that compassion and bodhicitta are not ornaments but causes of awakening itself.",
            overview: "Candrakirti begins not with abstraction but with compassion. Even the most refined Middle Way reasoning is grounded in concern for beings and the arising of bodhicitta.",
            paragraphs: [
                "This matters because emptiness can be misunderstood as philosophical detachment. Candrakirti’s opening refuses that split.",
                "Compassion, non-dual understanding, and bodhicitta are presented together. Insight without compassion is incomplete; compassion without wisdom remains unstable.",
                "The Middle Way is therefore not a cold intellectual discipline. It is a way of seeing that keeps the heart and view inseparable."
            ],
            keyPoints: [
                "Compassion is foundational, not secondary.",
                "Bodhicitta and non-dual understanding belong together.",
                "Middle Way training should not become emotionally dry."
            ],
            attributionNote: "In-app note based on the public Lotsawa House quotations page for the Madhyamakāvatāra."
        ),
        TeachingEntry(
            id: "dharmakirti-clear-light",
            title: "Clear Light and Adventitious Stains",
            teacher: "Dharmakirti",
            lineage: "Pramana / Buddhist philosophy",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/indian-masters/dharmakirti/pramanavarttika-quotations",
            cardSummary: "A terse philosophical pointer: the mind’s nature is luminous, while obscurations are contingent rather than intrinsic.",
            overview: "Dharmakirti’s famous lines are powerful because they are so economical. They distinguish between what mind is and what temporarily clouds it.",
            paragraphs: [
                "If defilements were the nature of mind itself, liberation would make little sense. But if they are adventitious, then practice becomes intelligible and workable.",
                "The quotation also links self-grasping to the cascade of attachment, aversion, and fault. The trouble begins when a solid 'I' is taken for granted.",
                "This is why these verses remain so widely cited: they offer philosophical precision that is also directly usable in practice."
            ],
            keyPoints: [
                "Mind’s nature is luminous.",
                "Obscurations are contingent, not essential.",
                "Self-grasping gives rise to attachment and aversion."
            ],
            attributionNote: "In-app note based on the public Lotsawa House quotations page for Dharmakīrti."
        ),
        TeachingEntry(
            id: "dilgo-heart-advice",
            title: "Heart Advice in Four Lines",
            teacher: "Dilgo Khyentse Rinpoche",
            lineage: "Nyingma / Rime",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/dilgo-khyentse/heart-advice-do-not-forget",
            cardSummary: "Four direct reminders: do not forget the teacher, the nature of mind, death, or beings.",
            overview: "The force of this short advice is its compression. It cuts straight to four axes of practice that can be carried at all times.",
            paragraphs: [
                "First, do not let devotion fade into abstraction. Remember the teacher and return to the source of blessing again and again, not sentimentally but as a living orientation.",
                "Second, turn inward and look directly at the mind itself. The advice is not to manage endless thought-content but to know the one who is distracted.",
                "Third, do not hide from impermanence. Remembering death is not presented as gloom, but as the energy that keeps the path honest and urgent.",
                "Fourth, do not forget beings. Compassion and dedication prevent practice from collapsing back into spiritual self-protection."
            ],
            keyPoints: [
                "Devotion keeps practice connected to blessing.",
                "Looking into mind is more important than chasing thoughts.",
                "Remembering death sharpens diligence.",
                "Compassion turns practice outward toward beings."
            ],
            attributionNote: "Based on a public Lotsawa House translation. Attribution and source link retained."
        ),
        TeachingEntry(
            id: "jamgon-kongtrul-lhawang-tashi",
            title: "Advice to Lhawang Tashi",
            teacher: "Jamgon Kongtrul Lodro Thaye",
            lineage: "Rime / Kagyu",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/jamgon-kongtrul/advice-to-lhawang-tashi",
            cardSummary: "A broad and grounded teaching on watching speech and mind, cultivating compassion, and holding devotion as a vital point.",
            overview: "Jamgon Kongtrul’s advice moves freely from ethics to bodhichitta to the nature of mind, showing how the whole path hangs together.",
            paragraphs: [
                "He begins very practically: among others, watch speech; alone, watch the mind. Faults tend to root in the mind and emerge through the mouth, so these two doors need guarding.",
                "He then turns to a deeper view: the drama of samsara and nirvana appears through mind. Joy and suffering, high and low, all arise within this field of experience and have to be understood there.",
                "Compassion is not an optional sentiment added later. It arises naturally when one sees how beings are driven by confusion and pain. Yet compassion also has to be freed from grasping by realising its emptiness.",
                "The path is completed by devotion, merit, and ethical steadiness. One should avoid wrongdoing, cultivate virtue, hold bodhichitta continuously, and dedicate merit cleanly."
            ],
            keyPoints: [
                "Guard speech in company and mind in solitude.",
                "Understand experience through mind rather than chasing externals.",
                "Let compassion arise, then free it from grasping.",
                "Keep devotion, virtue, and dedication intact."
            ],
            attributionNote: "Based on a public Lotsawa House translation. Attribution and source link retained."
        ),
        TeachingEntry(
            id: "longchenpa-heart-advice",
            title: "Thirty Pieces of Heart Advice",
            teacher: "Longchen Rabjam",
            lineage: "Nyingma",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/longchen-rabjam/30-stanzas-of-advice",
            cardSummary: "A fierce and unsentimental body of advice on renunciation, simplicity, restraint, and staying close to real practice.",
            overview: "Longchenpa repeatedly exposes the ways religious life becomes another field of distraction, ambition, and conflict unless one returns to simplicity.",
            paragraphs: [
                "Again and again he warns against turning Dharma into reputation, institution-building, or social display. Even apparently virtuous activity can become another form of attachment when the mind is not examined.",
                "The practical medicine is simplicity: fewer aspirations, less noise, less strategic speech, less busyness, fewer possessions, and less dependence on status and retinue.",
                "He is especially sharp about the subtle forms of attachment that hide inside teaching, debating, leading, organising, and collecting support. The outer appearance of Dharma is not the same as inner renunciation.",
                "Yet the conclusion is not withdrawal into indifference. Emptiness and compassion are to be held together, and practice is meant to mature into stable, undistracted benefit for beings."
            ],
            keyPoints: [
                "Do not mistake religious activity for practice itself.",
                "Simplicity protects renunciation.",
                "Watch the mind inside praise, teaching, and service.",
                "Hold emptiness and compassion together."
            ],
            attributionNote: "Based on a public Lotsawa House translation. Attribution and source link retained."
        ),
        TeachingEntry(
            id: "tsongkhapa-three-principal-aspects",
            title: "Three Principal Aspects of the Path",
            teacher: "Je Tsongkhapa",
            lineage: "Gelug",
            sourceLabel: "Lotsawa House",
            sourceURL: "https://www.lotsawahouse.org/tibetan-masters/tsongkhapa/three-principal-aspects",
            cardSummary: "A classical map of the path held in three inseparable elements: renunciation, bodhichitta, and wisdom.",
            overview: "Tsongkhapa’s structure is famously clean. The path is not complete unless these three are held together as one integrated training.",
            paragraphs: [
                "Renunciation is not disgust at life. It is the sober understanding that cyclic existence cannot satisfy the mind’s deepest longing, and that the opportunity of this life should not be wasted.",
                "Bodhichitta prevents liberation from becoming private. The suffering of beings is brought fully into view so that awakening is sought for the sake of all, not only for personal release.",
                "Wisdom then cuts at the root. Without insight into dependent origination and emptiness, even sincere renunciation and compassion will not sever samsara at its source.",
                "Tsongkhapa’s brilliance is to show that these are not separate modules. Renunciation deepens bodhichitta, bodhichitta protects wisdom from coldness, and wisdom keeps both from becoming sentimental or rigid."
            ],
            keyPoints: [
                "Renunciation releases the grip of samsaric fascination.",
                "Bodhichitta universalises the aim of practice.",
                "Wisdom sees dependent origination and emptiness together.",
                "The three must mature together."
            ],
            attributionNote: "Based on a public Lotsawa House translation. Attribution and source link retained."
        )
    ]
}

private struct TeachingCard: View {
    let teaching: TeachingEntry

    private var cardBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .secondarySystemBackground)
#else
        Color(NSColor.windowBackgroundColor)
#endif
    }

    private var subtitleText: String {
        let parts = [teaching.teacher, teaching.lineage]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(teaching.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if subtitleText.isEmpty == false {
                    Text(subtitleText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Text(teaching.cardSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if teaching.sourceLabel.isEmpty == false {
                Text(teaching.sourceLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackgroundColor.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct TeachingDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let teaching: TeachingEntry

    private var detailBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: colorScheme == .dark ? .black : .systemBackground)
#else
        colorScheme == .dark ? Color.black : Color.white
#endif
    }

    private var teacherLineText: String {
        let parts = [teaching.teacher, teaching.lineage]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(teaching.title)
                        .font(.title3.weight(.semibold))

                    if teacherLineText.isEmpty == false {
                        Text(teacherLineText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(teaching.overview)
                    .font(.body)

                ForEach(teaching.paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                if teaching.keyPoints.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Key points")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(teaching.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.45))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 7)

                                Text(point)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                if teaching.attributionNote.isEmpty == false {
                    Text(teaching.attributionNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let sourceURL = teaching.sourceURL, let url = URL(string: sourceURL) {
                    Link(destination: url) {
                        Label("Read original source", systemImage: "arrow.up.right")
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(red: 0.45, green: 0.24, blue: 0.19))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(detailBackgroundColor.ignoresSafeArea())
        .navigationTitle("Teaching")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
