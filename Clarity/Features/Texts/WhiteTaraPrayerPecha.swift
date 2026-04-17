import Foundation

enum WhiteTaraPrayerPecha {
    static let title = "White Tara Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "white-tara-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            རབ་དཀར་ཟླ་ཞུན་སྟོང་གི་ལང་ཚོ་ཅན། །
            མཚན་དཔེའི་སྐུ་མཆོག་འཆི་བདག་བདུད་བཅོམ་མ། །
            ཚེ་དང་ཡེ་ཤེས་དངོས་གྲུབ་མཆོག་སྟེར་བ། །
            རྗེ་བཙུན་ཡིད་བཞིན་འཁོར་ལོར་གསོལ་བ་འདེབས། །
            """,
            transliteration: """
            rabkar da zhün tong gi langtso chen
            tsenpé ku chok chidak dü chom ma
            tsé dang yeshe ngödrub chok terwa
            jetsün yizhin khorlor solwa deb
            """,
            english: """
            Brilliant white, with the vibrant vigor of a thousand moons,
            In your supreme form of major and minor marks, you are the destroyer of Māra, Lord of Death,
            And bestower of the supreme siddhis of longevity and wisdom—
            Noble Tara, Wish-Fulfilling Wheel, to you I pray!
            """
        ),
        PechaPage(
            id: "white-tara-prayer-mantra",
            pageNumber: 2,
            section: .mantra,
            tibetan: "ཨོཾ་ཏཱ་རེ་ཏུཏྟཱ་རེ་ཏུ་རེ་མ་མ་ཨ་ཡུར་པུཎྱེ་ཛྙཱ་ན་པུཥྚིཾ་ཀུ་རུ་སོ་ཧཱ།",
            transliteration: nil,
            english: "Om Tare Tuttare Ture Mama Ayur Punye Jnana Pushtim Kuru Soha"
        )
    ]
}
