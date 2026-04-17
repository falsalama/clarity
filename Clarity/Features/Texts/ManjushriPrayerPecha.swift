import Foundation

enum ManjushriPrayerPecha {
    static let title = "Manjushri Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "manjushri-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            གང་ཚེ་བདག་གིས་གཞན་ཕན་སེམས་ཀྱིས་སུ། །
            སྙིང་དབུས་པདྨ་གཞོན་ནུར་ཁྱོད་དྲན་ནས། །
            ལེགས་བཤད་བདུད་རྩིའི་སྒྲ་དབྱངས་སྤྲོ་བགྱིད་ན། །
            འཇམ་དཔལ་བདག་གི་ཡིད་ལ་དཔལ་སྩོལ་ཅིག །
            """,
            transliteration: """
            gang tsé dak gi zhenpen sem kyi su
            nying ü pema zhönnur khyö dren né
            lek shé dütsi drayang tro gyi na
            jampal dak gi yi la pal tsol chik
            """,
            english: """
            As, out of the wish to benefit others,
            I visualize you upon the fresh lotus in my heart,
            May the melodious sound of your nectar-like speech,
            O Mañjuśrī, confer its splendour upon my mind!
            """
        ),
        PechaPage(
            id: "manjushri-prayer-mantra",
            pageNumber: 2,
            section: .mantra,
            tibetan: "ཨོཾ་ཨ་ར་པ་ཙ་ན་དྷཱིཿ",
            transliteration: "om a ra pa tsa na dhih",
            english: nil
        )
    ]
}
