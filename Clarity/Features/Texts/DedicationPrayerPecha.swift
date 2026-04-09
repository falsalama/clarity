import Foundation

enum DedicationPrayerPecha {
    static let title = "Dedication Prayer"
    static let subtitle = "Dedication of Merit"

    static let pages: [PechaPage] = [
        PechaPage(
            id: "dedication-prayer-main",
            pageNumber: 1,
            section: .main,
            title: "Dedication of Merit",
            tibetan: """
            བསོད་ནམས་འདི་ཡིས་ཐམས་ཅད་གཟིགས་པ་ཉིད། །
            ཐོབ་ནས་ཉེས་པའི་དགྲ་རྣམས་ཕམ་བྱས་ཤིང་། །
            སྐྱེ་རྒ་ན་འཆིའི་རྦ་ཀློང་འཁྲུགས་པ་ཡི། །
            སྲིད་པའི་མཚོ་ལས་འགྲོ་བ་སྒྲོལ་བར་ཤོག །
            """,
            transliteration: """
            sönam di yi tamché zikpa nyi
            tob né nyepé dra nam pamjé shing
            kyé ga na chi balong trukpa yi
            sipé tso lé drowa drolwar shok
            """,
            english: """
            Through this merit, may all beings attain the omniscient state of enlightenment,
            And conquer the enemy of faults and delusion,
            May they all be liberated from this ocean of saṃsāra
            And from its pounding waves of birth, old age, sickness and death!

            Taken from the Jātakas.
            """
        )
    ]
}
