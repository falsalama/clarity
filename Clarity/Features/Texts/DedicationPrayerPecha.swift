import Foundation

enum DedicationPrayerPecha {
    static let title = "Dedication Prayer"
    static let subtitle = "Dedication of Merit"

    static let pages: [PechaPage] = [
        PechaPage(
            id: "dedication-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            དགེ་བ་འདི་ཡིས་མྱུར་དུ་བདག །
            བླ་མ་སངས་རྒྱས་འགྲུབ་གྱུར་ནས། །
            འགྲོ་བ་གཅིག་ཀྱང་མ་ལུས་པ། །
            དེ་ཡི་ས་ལ་འགོད་པར་ཤོག །
            """,
            transliteration: """
            ge wa di yi nyur du dak
            lama sangye drub gyur ne
            drowa chik kyang ma lu pa
            de yi sa la gö par shok
            """,
            english: """
            Due to this virtue, may I quickly
            attain the state of a Guru-Buddha,
            and lead every being, without exception,
            to that very state.
            """
        )
    ]
}
