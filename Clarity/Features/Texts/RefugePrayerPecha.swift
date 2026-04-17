import Foundation

enum RefugePrayerPecha {
    static let title = "Refuge Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "refuge-prayer-main",
            pageNumber: 1,
            section: .main,
            title: "Refuge and Bodhicitta",
            tibetan: """
            སངས་རྒྱས་ཆོས་དང་ཚོགས་ཀྱི་མཆོག་རྣམས་ལ། །
            བྱང་ཆུབ་བར་དུ་བདག་ནི་སྐྱབས་སུ་མཆི། །
            བདག་གིས་སྦྱིན་སོགས་བགྱིས་པའི་བསོད་ནམས་ཀྱིས། །
            འགྲོ་ལ་ཕན་ཕྱིར་སངས་རྒྱས་འགྲུབ་པར་ཤོག །
            """,
            transliteration: """
            sangye chö dang tsok kyi chok nam la
            jangchub bardu dak ni kyab su chi
            dak gi jinsok gyi pé sönam kyi
            dro la pen chir sanggye drubpar shok
            """,
            english: """
            In the Buddha, Dharma and Supreme Assembly
            I take refuge until awakening.
            Through the merit of generosity and the other virtues,
            May I accomplish buddhahood for the benefit of all beings.
            """
        )
    ]
}
