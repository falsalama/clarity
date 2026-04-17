import Foundation

enum GreenTaraPrayerPecha {
    static let title = "Green Tara Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "green-tara-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            དུས་གསུམ་རྒྱལ་བ་སྲས་བཅས་སྐྱེད་པའི་ཡུམ། །
            བཅོམ་ལྡན་རྗེ་བཙུན་འཕགས་མ་སྒྲོལ་མ་དང་། །
            དབྱེར་མེད་བླ་མ་སངས་རྒྱས་ཀུན་འདུས་ལ། །
            སྒོ་གསུམ་རྩེ་གཅིག་གུས་པས་གསོལ་བ་འདེབས། །

            འཆི་མེད་རྡོ་རྗེ་བདེ་བའི་ཡེ་ཤེས་ཀྱིས། །
            སྨིན་ཅིང་གྲོལ་ནས་དོན་གཉིས་མྱུར་འགྲུབ་ཤོག །
            """,
            transliteration: """
            gyalwa kün gyi tukjé trinlé nam
            chikdü jetsün nyurma pamö zhab
            solwa deb so di chi bardo kün
            jik dang dukngal tsok lé kyab tu sol
            """,
            english: """
            Embodiment of the compassion and activity of all Victorious Ones,
            Noble Lady, swift and heroic,
            To you I pray: in this life, the next and the intermediate state,
            May you protect us from the hosts of fears and sufferings!
            """
        ),
        PechaPage(
            id: "green-tara-prayer-mantra",
            pageNumber: 2,
            section: .mantra,
            tibetan: "ཨོཾ་ཏཱ་རེ་ཏུཏྟཱ་རེ་ཏུ་རེ་སྭཱ་ཧཱ།",
            transliteration: nil,
            english: "Om Tare Tuttare Ture Soha"
        )
    ]
}
