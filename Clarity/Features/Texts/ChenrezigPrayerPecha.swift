import Foundation

enum ChenrezigPrayerPecha {
    static let title = "Chenrezig Prayer"
    static let subtitle = ""

    static let pages: [PechaPage] = [
        PechaPage(
            id: "chenrezig-prayer-main",
            pageNumber: 1,
            section: .main,
            tibetan: """
            ན་མོ་གུ་རུ་ལོ་ཀེ་ཤྭ་ར་ཡ།

            སྐྱབས་གནས་ཀུན་འདུས་ངོ་བོ་བཀའ་དྲིན་ཅན། །
            བླ་མ་སྤྱན་རས་གཟིགས་ལ་གསོལ་བ་འདེབས། །
            """,
            transliteration: """
            Namo guru lokeśvaraya!

            kyabné kündü ngowo kadrin chen
            lama chenré zik la solwa dep
            """,
            english: """
            Namo guru lokeśvaraya!

            In essence you are the embodiment of all sources of refuge,
            Gracious lama, Avalokiteśvara, to you I pray.
            """
        ),
        PechaPage(
            id: "chenrezig-prayer-mantra",
            pageNumber: 2,
            section: .mantra,
            tibetan: "ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ།",
            transliteration: "om mani padme hung",
            english: nil
        )
    ]
}
