import Foundation

enum BodhicittaPrayerPecha {
    static let title = "Bodhicitta Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "bodhicitta-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            བྱང་ཆུབ་སེམས་མཆོག་རིན་པོ་ཆེ། །
            མ་སྐྱེས་པ་རྣམས་སྐྱེ་གྱུར་ཅིག །
            སྐྱེས་པ་ཉམས་པ་མེད་པ་དང་། །
            གོང་ནས་གོང་དུ་འཕེལ་བར་ཤོག །
            """,
            transliteration: """
            jang chub sem chok rinpoche
            ma kye pa nam kye gyur chik
            kye pa nyam pa me pa dang
            gong ne gong du phel war shok
            """,
            english: """
            May precious bodhicitta,
            Not yet born, arise and grow.
            May that born have no decline,
            But increase forever more.
            """
        )
    ]
}
