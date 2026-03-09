import Foundation

enum HeartSutraPecha {
    static let title = "Heart Sutra"
    static let subtitle = "The Sutra of the Heart of the Perfection of Wisdom"
    static let source = "Pecha edition"
    static let pages: [PechaPage] = [
        PechaPage(
            id: "heart-cover",
            section: .cover,
            title: "The Sutra of the Heart of the Perfection of Wisdom",
        ),

        PechaPage(
            id: "heart-title",
            section: .title,
            title: "The Sutra of the Heart of the Perfection of Wisdom",
            tibetan: "བཅོམ་ལྡན་འདས་མ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པའི་སྙིང་པོ།",
            transliteration: "Chom Dän Da Ma She Rab Chi Pa Rol Tu Chin Pa’i Nying Po",
            english: "The Sutra of the Heart of the Perfection of Wisdom"
        ),

        PechaPage(
            id: "heart-frontispiece",
            section: .image,
            title: "",
            imageName: "heart-sutra-woodblock"
        ),

        PechaPage(
            id: "heart-opening-1",
            pageNumber: 1,
            section: .opening,
            tibetan: "བཅོམ་ལྡན་འདས་མ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་མ་ལ་ཕྱག་འཚལ་ལོ།",
            transliteration: "Chom-Dän-Da Ma She Rab Chi Pa Rol Tu Chin Ma La Chag Tsal Lo",
            english: "Homage to the Noble Goddess, the Heart of the Perfection of Wisdom."
        ),

        PechaPage(
            id: "heart-opening-2",
            pageNumber: 2,
            section: .opening,
            tibetan: "Placeholder Tibetan from your edition page 2.",
            transliteration: "Placeholder transliteration from your edition page 2.",
            english: "Thus have I heard at one time, the Blessed One was dwelling in Rajagriha on Massed Vultures Mountain..."
        ),

        PechaPage(
            id: "heart-opening-3",
            pageNumber: 3,
            section: .opening,
            tibetan: "Placeholder Tibetan from your edition page 3.",
            transliteration: "Placeholder transliteration from your edition page 3.",
            english: "At that time also, Superior Avalokiteshvara, the bodhisattva, the great being, was looking perfectly at the practice of the profound perfection of wisdom..."
        ),

        PechaPage(
            id: "heart-main-4",
            pageNumber: 4,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 4.",
            transliteration: "Placeholder transliteration from your edition page 4.",
            english: "Then, through the power of Buddha, the venerable Shariputra said to the Superior Avalokiteshvara..."
        ),

        PechaPage(
            id: "heart-main-5",
            pageNumber: 5,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 5.",
            transliteration: "Placeholder transliteration from your edition page 5.",
            english: "Thus he spoke, and the Superior Avalokiteshvara replied..."
        ),

        PechaPage(
            id: "heart-main-6",
            pageNumber: 6,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 6.",
            transliteration: "Placeholder transliteration from your edition page 6.",
            english: "Form is emptiness; emptiness is form. Emptiness is not other than form; form also is not other than emptiness."
        ),

        PechaPage(
            id: "heart-main-7",
            pageNumber: 7,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 7.",
            transliteration: "Placeholder transliteration from your edition page 7.",
            english: "Likewise, feeling, discrimination, compositional factors and consciousness are empty..."
        ),

        PechaPage(
            id: "heart-main-8",
            pageNumber: 8,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 8.",
            transliteration: "Placeholder transliteration from your edition page 8.",
            english: "They are not produced and do not cease. They have no defilement and no separation from defilement..."
        ),

        PechaPage(
            id: "heart-main-9",
            pageNumber: 9,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 9.",
            transliteration: "Placeholder transliteration from your edition page 9.",
            english: "There is no eye, no ear, no nose, no tongue, no body, no mind..."
        ),

        PechaPage(
            id: "heart-main-10",
            pageNumber: 10,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 10.",
            transliteration: "Placeholder transliteration from your edition page 10.",
            english: "There is no ignorance and no exhaustion of ignorance..."
        ),

        PechaPage(
            id: "heart-main-11",
            pageNumber: 11,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 11.",
            transliteration: "Placeholder transliteration from your edition page 11.",
            english: "Therefore, Shariputra, because there is no attainment, all bodhisattvas rely on and abide in the perfection of wisdom..."
        ),

        PechaPage(
            id: "heart-main-12",
            pageNumber: 12,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 12.",
            transliteration: "Placeholder transliteration from your edition page 12.",
            english: "Also, all the buddhas who perfectly reside in the three times..."
        ),

        PechaPage(
            id: "heart-main-13",
            pageNumber: 13,
            section: .main,
            tibetan: "Placeholder Tibetan from your edition page 13.",
            transliteration: "Placeholder transliteration from your edition page 13.",
            english: "Therefore, the mantra of the perfection of wisdom, the mantra of great knowledge..."
        ),

        PechaPage(
            id: "heart-mantra-14",
            pageNumber: 14,
            section: .mantra,
            tibetan: "ཏདྱ་ཐཱ། ཨོཾ་ག་ཏེ་ག་ཏེ་པ་ར་ག་ཏེ་པ་ར་སཾ་ག་ཏེ་བོ་དྷི་སྭཱ་ཧཱ།",
            transliteration: "TA YA THA: OM GATE GATE PARAGATE PARASAMGATE BODHI SOHA",
            english: "The mantra of the perfection of wisdom is proclaimed."
        ),

        PechaPage(
            id: "heart-closing-15",
            pageNumber: 15,
            section: .closing,
            tibetan: "Placeholder Tibetan from your edition page 15.",
            transliteration: "Placeholder transliteration from your edition page 15.",
            english: "Then the Blessed One arose from that concentration..."
        ),

        PechaPage(
            id: "heart-closing-16",
            pageNumber: 16,
            section: .closing,
            tibetan: "Placeholder Tibetan from your edition page 16.",
            transliteration: "Placeholder transliteration from your edition page 16.",
            english: "Good, good, O son of the lineage..."
        ),

        PechaPage(
            id: "heart-closing-17",
            pageNumber: 17,
            section: .closing,
            tibetan: "Placeholder Tibetan from your edition page 17.",
            transliteration: "Placeholder transliteration from your edition page 17.",
            english: "The profound perfection of wisdom should be practised in that way..."
        ),

        PechaPage(
            id: "heart-closing-18",
            pageNumber: 18,
            section: .closing,
            tibetan: "Placeholder Tibetan from your edition page 18.",
            transliteration: "Placeholder transliteration from your edition page 18.",
            english: "The Superior Avalokiteshvara, the bodhisattva, the great being..."
        ),

        PechaPage(
            id: "heart-closing-19",
            pageNumber: 19,
            section: .closing,
            tibetan: "Placeholder Tibetan from your edition page 19.",
            transliteration: "Placeholder transliteration from your edition page 19.",
            english: "And highly praised what had been spoken by the Blessed One."
        ),

        PechaPage(
            id: "heart-dedication",
            section: .dedication,
            title: "Dedication",
            english: """
            If this text contains any errors then this is through no fault but our own.

            This printed edition includes a source-specific dedication.
            In Clarity, the dedication should later be offered as a separate, broad and non-lineage-specific option.
            """
        )
    ]
}
