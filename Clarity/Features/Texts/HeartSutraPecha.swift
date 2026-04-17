import Foundation

enum HeartSutraPecha {
    static let title = "Heart Sutra"
    static let subtitle = ""
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
            tibetan: """
            ༄༅། །འཕགས་པ་ཤེས་རབ་ཀྱི་སྙིང་པོ་ཞེས་བྱ་བ་ཐེག་པ་ཆེན་པོའི་མདོ།
            """,
            transliteration: """
            Pakpa She Rab Kyi Nyingpo Zhe Ja Wa Tekpa Chenpö Do
            """
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
            tibetan: """
            བཅོམ་ལྡན་འདས་མ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ལ་ཕྱག་འཚལ་ལོ། །

            འདི་སྐད་བདག་གིས་ཐོས་པ་དུས་གཅིག་ན། བཅོམ་ལྡན་འདས་རྒྱལ་པོའི་ཁབ་བྱ་རྒོད་ཕུང་པོའི་རི་ལ་དགེ་སློང་གི་དགེ་འདུན་ཆེན་པོ་དང༌།
            """,
            transliteration: """
            Chom-Dän-Da Ma She Rab Chi Pa Rol Tu Chin Ma La Chag Tsal Lo

            Di-kä dak-gi tö-pa dü-chik-na / chom-dän-dä gyäl-pöi-kap-na ja-gö pung-pöi ri-la ge-long-gi ge-dün chen-po-dang /
            """,
            english: """
            Homage to the Noble Goddess, the Heart of the Perfection of Wisdom!

            Thus have I heard at one time, the Blessed One was dwelling in Rajagriha on Massed Vultures Mountain,
            """
        ),

        PechaPage(
            id: "heart-opening-2",
            pageNumber: 2,
            section: .opening,
            tibetan: """
            བྱང་ཆུབ་སེམས་དཔའི་དགེ་འདུན་ཆེན་པོ་དང་ཐབས་གཅིག་ཏུ་བཞུགས་ཏེ།

            དེའི་ཚེ་བཅོམ་ལྡན་འདས་ཟབ་མོ་སྣང་བ་ཞེས་བྱ་བ་ཆོས་ཀྱི་རྣམ་གྲངས་ཀྱི་ཏིང་ངེ་འཛིན་ལ་སྙོམས་པར་ཞུགས་སོ། །
            """,
            transliteration: """
            jang-chup-sem-päi ge-dün chen-po-dang tap-chik-tu zhuk-te /

            dei tse chom-dän-dä zap-mo nang-wa zhe-ja-wäi chö-kyi nam-drang-gi ting-nge-dzin-la nyom-par zhuk-so //
            """,
            english: """
            together in one method with a great assembly of monks and a great assembly of Bodhisattvas.

            At that time the Blessed One was absorbed in the concentration of the countless aspects of phenomena called "Profound Illumination".
            """
        ),

        PechaPage(
            id: "heart-opening-3",
            pageNumber: 3,
            section: .opening,
            tibetan: """
            ཡང་དེའི་ཚེ་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་འཕགས་པ་སྤྱན་རས་གཟིགས་དབང་ཕྱུག་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཟབ་མོ་སྤྱོད་པ་ཉིད་ལ་རྣམ་པར་བལྟ་ཞིང་།

            ཕུང་པོ་ལྔ་པོ་དེ་དག་ལ་ཡང་རང་བཞིན་གྱིས་སྟོང་པར་རྣམ་པར་བལྟའོ། །
            """,
            transliteration: """
            Yang dei tse jang-chup-sem-pa sem-pa-chen-po pak-pa chän-rä-zik wang-chuk she-rap-kyi pa-röl-tu-chin-pa zap-mo chö-pa-nyi-la, nam-par ta-zhing /

            pung-po nga-po de-dak-la yang rang-zhin-gyi tong-par nam-par ta wo /
            """,
            english: """
            At that time also, Superior Avalokiteshvara, the bodhisattva, the great being, was looking perfectly at the practice of the profound perfection of wisdom, perfectly looking at the emptiness of inherent existence of the five aggregates also.
            """
        ),

        PechaPage(
            id: "heart-main-4",
            pageNumber: 4,
            section: .main,
            tibetan: """
            དེ་ནས་སངས་རྒྱས་ཀྱི་མཐུས། ཚེ་དང་ལྡན་པ་ཤཱ་རིའི་བུས་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་འཕགས་པ་སྤྱན་རས་གཟིགས་དབང་ཕྱུག་ལ་འདི་སྐད་ཅེས་སྨྲས་སོ། །

            རིགས་ཀྱི་བུ་གང་ལ་ལ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཟབ་མོ་སྤྱོད་པ་སྤྱད་པར་འདོད་པ་དེས་ཇི་ལྟར་བསླབ་པར་བྱ།
            """,
            transliteration: """
            de-nä sang-gyä-kyi tü tse-dang-dän-pa shari-bü jang-chup-sem-pa sem-pa-chen-po pak-pa chän-rä-zik wang-chuk-la di-kä-che mä-so //

            rik-kyi bu gang-la-la she-rap-kyi pa-röl-tu chin-pa zap-möi chä-pa chö-par dö-pa de ji-tar lap-par ja /
            """,
            english: """
            Then, through the power of Buddha, the venerable Shariputra said to the Superior Avalokiteshvara, the Bodhisattva, the great being,

            "How should a son of the lineage train who wishes to engage in the practice of the profound perfection of wisdom?"
            """
        ),

        PechaPage(
            id: "heart-main-5",
            pageNumber: 5,
            section: .main,
            tibetan: """
            དེ་སྐད་ཅེས་སྨྲས་པ་དང༌། བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་འཕགས་པ་སྤྱན་རས་གཟིགས་དབང་ཕྱུག་གིས་ཚེ་དང་ལྡན་པ་ཤཱ་ར་དྭ་ཏིའི་བུ་ལ་འདི་སྐད་ཅེས་སྨྲས་སོ། །

            ཤཱ་རིའི་བུ་རིགས་ཀྱི་བུ་འམ་རིགས་ཀྱི་བུ་མོ་གང་ལ་ལ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཟབ་མོ་སྤྱོད་པ་སྤྱད་པར་འདོད་པ་དེས་འདི་ལྟར་རྣམ་པར་བལྟ་བར་བྱ་སྟེ།
            """,
            transliteration: """
            de-kä-che mä-pa-dang / jang-chup-sem-pa sem-pa-chen-po pak-pa chän-rä-zik wang-chuk-gi tse-dang-dän-pa sha-ra-da-ti-bu-la di-kä-che mä-so //

            shari-bu, rik-kye-bu-am rik-kyi-bu-mo gang-la-la she-rap-kyi pa-röl-tu-chin-pa zap-möi chä-pa chö-par dö-pa-de di-tar nam-par ta war ja-te /
            """,
            english: """
            Thus he spoke, and the Superior Avalokiteshvara, the bodhisattva, the great being, replied to the venerable Shariputra as follows:

            "Shariputra, whatever son or daughter of the lineage wishes to engage in the practice of the profound perfection of wisdom should look perfectly like this:"
            """
        ),

        PechaPage(
            id: "heart-main-6",
            pageNumber: 6,
            section: .main,
            tibetan: """
            ཕུང་པོ་ལྔ་པོ་དེ་དག་ཀྱང་རང་བཞིན་གྱིས་སྟོང་པར་རྣམ་པར་ཡང་དག་པར་རྗེས་སུ་བལྟའོ། །

            གཟུགས་སྟོང་པའོ། །སྟོང་པ་ཉིད་ཀྱང་གཟུགས་སོ། ། གཟུགས་ལས་སྟོང་པ་ཉིད་གཞན་མ་ཡིན་ནོ། །སྟོང་པ་ཉིད་ལས་ཀྱང་གཟུགས་གཞན་མ་ཡིན་ནོ། །
            """,
            transliteration: """
            pung-po nga-po de-dak kyang / rang-zhin-gyi tong-par nam-par yang-dak-par je-su-ta-wo //

            zuk tong-pa-wo // tong-pa-nyi zuk-so // zuk-lä tong-pa-nyi zhän ma-yin, tong-pa-nyi-lä kyang zuk zhän ma-yin-no //
            """,
            english: """
            subsequently looking perfectly and correctly at the emptiness of inherent existence of the five aggregates also.

            "Form is emptiness; emptiness is form. Emptiness is not other than form; form also is not other than emptiness.
            """
        ),

        PechaPage(
            id: "heart-main-7",
            pageNumber: 7,
            section: .main,
            tibetan: """
            དེ་བཞིན་དུ་ཚོར་བ་དང༌། འདུ་ཤེས་དང༌། འདུ་བྱེད་དང༌། རྣམ་པར་ཤེས་པ་རྣམས་སྟོང་པའོ། །

            ཤཱ་རིའི་བུ་དེ་ལྟ་བས་ན་ཆོས་ཐམས་ཅད་སྟོང་པ་ཉིད་དེ། མཚན་ཉིད་མེད་པ། མ་སྐྱེས་པ།
            """,
            transliteration: """
            de-zhin-du tsor-wa-dang / du-she-dang / du-je-dang / nam-par-she-pa-nam tong-pa-wo //

            sha-ri-bu de-tar chö tam-chä tong-pa-nyi-de / tsän-nyi me-pa / ma-kye-pa /
            """,
            english: """
            Likewise, feeling, discrimination, compositional factors and consciousness are empty.

            Shariputra, like this all phenomena are merely empty, having no characteristics.
            """
        ),

        PechaPage(
            id: "heart-main-8",
            pageNumber: 8,
            section: .main,
            tibetan: """
            མ་འགགས་པ། དྲི་མ་མེད་པ། དྲི་མ་དང་བྲལ་བ་མེད་པ། བྲི་བ་མེད་པ། གང་བ་མེད་པའོ། །

            ཤཱ་རིའི་བུ་དེ་ལྟ་བས་ན་སྟོང་པ་ཉིད་ལ་གཟུགས་མེད། ཚོར་བ་མེད། འདུ་ཤེས་མེད། འདུ་བྱེད་རྣམས་མེད། རྣམ་པར་ཤེས་པ་མེད།
            """,
            transliteration: """
            ma-gak-pa / dri-ma me-pa / dri-ma-dang dräl-wa me-pa / dri-wa me-pa / gang-wa me-pa-wo //

            Shari-bu de-te-wä-na tong-pa-nyi-la zuk me / tsor-wa me / du-she me / du-je-nam me / nam-par-she-pa me /
            """,
            english: """
            They are not produced and do not cease. They have no defilement and no separation from defilement. They have no decrease and no increase.

            "Therefore, Shariputra, in emptiness there is no form, no feeling, no discrimination, no compositional factors, no consciousness.
            """
        ),

        PechaPage(
            id: "heart-main-9",
            pageNumber: 9,
            section: .main,
            tibetan: """
            མིག་མེད། རྣ་བ་མེད། སྣ་མེད། ལྕེ་མེད། ལུས་མེད། ཡིད་མེད། གཟུགས་མེད། སྒྲ་མེད། དྲི་མེད། རོ་མེད། རེག་བྱ་མེད། ཆོས་མེད་དོ། །

            མིག་གི་ཁམས་མེད་པ་ནས་ཡིད་ཀྱི་ཁམས་མེད། ཡིད་ཀྱི་རྣམ་པར་ཤེས་པའི་ཁམས་ཀྱི་བར་དུ་ཡང་མེད་དོ། །
            """,
            transliteration: """
            mik me / na-wa me / na me / che me / lu me / yi me / zuk me / dra me / dri me / ro me / rek-ja me / chö me-do //

            mik-gi kam me-pa-na / yi-kyi kam me / yi-kyi nam-par-she-päi kam-kyi bar-du yang me-do //
            """,
            english: """
            There is no eye, no ear, no nose, no tongue, no body, no mind: no form, no sound, no smell, no taste, no tactile object, no phenomenon.

            There is no eye element and so forth, up to no mind element, and also up to no element of mental consciousness.
            """
        ),

        PechaPage(
            id: "heart-main-10",
            pageNumber: 10,
            section: .main,
            tibetan: """
            མ་རིག་པ་མེད། མ་རིག་པ་ཟད་པ་མེད་པ་ནས་རྒ་ཤི་མེད། རྒ་ཤི་ཟད་པའི་བར་དུ་ཡང་མེད་དོ། །

            སྡུག་བསྔལ་བ་དང༌། ཀུན་འབྱུང་བ་དང༌། འགོག་པ་དང༌། ལམ་མེད། ཡེ་ཤེས་མེད། ཐོབ་པ་མེད། མ་ཐོབ་པ་ཡང་མེད་དོ། །
            """,
            transliteration: """
            mar-rik-pa me / ma-rik-pa zä-pa me-pa-na / ga-shi me / ga-shi za-päi bar-du yang me-do //

            de-zhin-du duk-ngäl-wa-dang / kün-jung-wa-dang / gok-pa-dang / lam me / ye-she me / top-pa me / ma-top-pa yang me-do //
            """,
            english: """
            There is no ignorance and no exhaustion of ignorance, and so forth up to no aging and death and no exhaustion of aging and death.

            Likewise, there is no suffering, origin, cessation or path; no exalted wisdom, no attainment and also no non-attainment.
            """
        ),

        PechaPage(
            id: "heart-main-11",
            pageNumber: 11,
            section: .main,
            tibetan: """
            ཤཱ་རིའི་བུ་དེ་ལྟ་བས་ན་བྱང་ཆུབ་སེམས་དཔའ་རྣམས་ཐོབ་པ་མེད་པའི་ཕྱིར། ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ལ་བརྟེན་ཅིང་གནས་ཏེ།

            སེམས་ལ་སྒྲིབ་པ་མེད་པས་སྐྲག་པ་མེད་དེ། ཕྱིན་ཅི་ལོག་ལས་ཤིན་ཏུ་འདས་ནས་མྱ་ངན་ལས་འདས་པའི་མཐར་ཕྱིན་ཏོ། །
            """,
            transliteration: """
            Shari-bu de-ta-wä-na / jang-chup-sem-pa-nam top-pa me-päi chir / she-rap-kyi pa-röl-tu-chin-pa-la ten-ching nä-te /

            sem-la drip-pa me-pä trak-pa me-de / chin-chi-lok-lä shin-tu dä-na / nya-ngän-lä-dä-päi tar chin-to //
            """,
            english: """
            Therefore, Shariputra, because there is no attainment, all bodhisattvas rely on and abide in the perfection of wisdom;

            their minds have no obstructions and no fear. Passing utterly beyond perversity, they attain the final state beyond sorrow.
            """
        ),

        PechaPage(
            id: "heart-main-12",
            pageNumber: 12,
            section: .main,
            tibetan: """
            དུས་གསུམ་དུ་རྣམ་པར་བཞུགས་པའི་སངས་རྒྱས་ཐམས་ཅད་ཀྱང་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ལ་བརྟེན་ནས།

            བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཏུ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་སོ། །
            """,
            transliteration: """
            dü-sum-du nam-par-zhuk-päi sang-gyä tam-chä kyang she-rap-kyi pa-röl-tu-chin-pa-la ten-nä /

            la-na-me-pa yang-dak-par dzok-päi jang-chup-tu ngön-par dzok-par sang-gyä-so //
            """,
            english: """
            Also, all the buddhas who perfectly reside in the three times, relying upon the perfection of wisdom,

            become manifest and complete buddhas in the state of unsurpassed, perfect and complete enlightenment.
            """
        ),

        PechaPage(
            id: "heart-main-13",
            pageNumber: 13,
            section: .main,
            tibetan: """
            དེ་ལྟ་བས་ན་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པའི་སྔགས། རིག་པ་ཆེན་པོའི་སྔགས། བླ་ན་མེད་པའི་སྔགས།

            མི་མཉམ་པ་དང་མཉམ་པའི་སྔགས། སྡུག་བསྔལ་ཐམས་ཅད་རབ་ཏུ་ཞི་བར་བྱེད་པའི་སྔགས། མི་བརྫུན་པས་ན་བདེན་པར་ཤེས་པར་བྱ་སྟེ།
            """,
            transliteration: """
            de-ta-wä-na she-rap-kyi pa-röl-tu-chin-päi ngak / rik-pa chen-pöi ngak / la-na-me-päi ngak /

            mi-nyam-pa-dang nyam-päi ngak / duk-ngäl tam-chä rap-tu zhi-war je-päi ngak / mi-dzün-pä-na den-par she-par ja-te /
            """,
            english: """
            Therefore, the mantra of the perfection of wisdom, the mantra of great knowledge, the unsurpassed mantra,

            the equal-to-the-unequalled mantra, the mantra that thoroughly pacifies all suffering, since it is not false, should be known as the truth.
            """
        ),

        PechaPage(
            id: "heart-mantra-14",
            pageNumber: 14,
            section: .mantra,
            tibetan: "ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པའི་སྔགས་སྨྲས་པ། ཏདྱ་ཐཱ། ཨོཾ་ག་ཏེ་ག་ཏེ་པཱ་ར་ག་ཏེ། པཱ་ར་སཾ་ག་ཏེ། བོ་དྷི་སྭཱ་ཧཱ།",
            transliteration: "TA YA THA: OM GATE GATE PARAGATE PARASAMGATE BODHI SOHA",
            english: "The mantra of the perfection of wisdom is proclaimed."
        ),

        PechaPage(
            id: "heart-closing-15",
            pageNumber: 15,
            section: .closing,
            tibetan: """
            ཤཱ་རིའི་བུ་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོས་དེ་ལྟར་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཟབ་མོ་ལ་བསླབ་པར་བྱའོ། །

            དེ་ནས་བཅོམ་ལྡན་འདས་ཏིང་ངེ་འཛིན་དེ་ལས་བཞེངས་ཏེ།
            """,
            transliteration: """
            Shari-bu / jang-chup-sem-pa sem-pa-chen-pö de-tar she-rap-kyi pa-röl-tu chin-pa zap-mo-la lap-par ja-wo //

            de-nä chom-dän-dä ting-nge-dzin de-lä zheng-te
            """,
            english: """
            "Shariputra, a bodhisattva, a great being, should train in the profound perfection of wisdom like this."

            Then the Blessed One arose from that concentration
            """
        ),

        PechaPage(
            id: "heart-closing-16",
            pageNumber: 16,
            section: .closing,
            tibetan: """
            བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་འཕགས་པ་སྤྱན་རས་གཟིགས་དབང་ཕྱུག་ལ་ལེགས་སོ་ཞེས་བྱ་བ་བྱིན་ནས།

            ལེགས་སོ་ལེགས་སོ། །རིགས་ཀྱི་བུ་དེ་དེ་བཞིན་ནོ། །རིགས་ཀྱི་བུ་དེ་དེ་བཞིན་ཏེ།
            """,
            transliteration: """
            jang-chup-sem-pa sem-pa-chen-po pak-pa chän-rä-zik wang-chuk-la lek-so-zhe ja-wa jin-na /

            lek-so, lek-so, rik-kyi-bu de de-zhin-no / rik-kyi bu de-de-zhin-te / ji-tar kyö-kyi tän-pa de-zhin-du /
            """,
            english: """
            and said to the Superior Avalokiteshvara, the bodhisattva, the great being, that he had spoken well.

            "Good, good, O son of the lineage. It is like that. Since it is like that, just as you have revealed,
            """
        ),

        PechaPage(
            id: "heart-closing-17",
            pageNumber: 17,
            section: .closing,
            tibetan: """
            ཇི་ལྟར་ཁྱོད་ཀྱིས་བསྟན་པ་དེ་བཞིན་དུ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཟབ་མོ་ལ་སྤྱད་པར་བྱ་སྟེ། དེ་བཞིན་གཤེགས་པ་རྣམས་ཀྱང་རྗེས་སུ་ཡི་རང་ངོ་། །

            བཅོམ་ལྡན་འདས་ཀྱིས་དེ་སྐད་ཅེས་བཀའ་སྩལ་ནས། ཚེ་དང་ལྡན་པ་ཤཱ་རིའི་བུ་དང༌།
            """,
            transliteration: """
            she-rap-kyi pa-röl-tu chin-pa zap-mo-la chä-par ja-te / de-zhin-shek-pa-nam kyang je-su-yi-rang-ngo //

            chom-dän-dä-kyi de-kä-che ka tsäl-na / tse-dang-dän-pa sha-ra-da-ti-bu-dang /
            """,
            english: """
            the profound perfection of wisdom should be practiced in that way, and the tathagatas will also rejoice."

            When the Blessed One had said this, the venerable Shariputra,
            """
        ),

        PechaPage(
            id: "heart-closing-18",
            pageNumber: 18,
            section: .closing,
            tibetan: """
            བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་འཕགས་པ་སྤྱན་རས་གཟིགས་དབང་ཕྱུག་དང༌།

            ཐམས་ཅད་དང་ལྡན་པའི་འཁོར་དེ་དག་དང༌། ལྷ་དང༌། མི་དང༌། ལྷ་མ་ཡིན་དང༌། དྲི་ཟར་བཅས་པའི་འཇིག་རྟེན་ཡི་རངས་ཏེ།
            """,
            transliteration: """
            jang-chup-sem-pa sem-pa-chen-po pak-pa chän-rä-zik wang-chuk-dang /

            tam-chä-dang dän-päi kor de-dak-dang / lha-dang / mi-dang lha-ma-yin-dang / dri-zar chä-päi jik-ten yi-rang-te /
            """,
            english: """
            the Superior Avalokiteshvara, the bodhisattva, the great being,

            that entire assembly of disciples as well as the worldly beings - gods, humans, demi-gods and spirits, were delighted
            """
        ),

        PechaPage(
            id: "heart-closing-19",
            pageNumber: 19,
            section: .closing,
            tibetan: """
            བཅོམ་ལྡན་འདས་ཀྱིས་གསུངས་པ་ལ་མངོན་པར་བསྟོད་དོ། །

            བཅོམ་ལྡན་འདས་མ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པའི་སྙིང་པོ་ཞེས་བྱ་བ་ཐེག་པ་ཆེན་པོའི་མདོ་རྫོགས་སོ།། །།
            """,
            transliteration: "chom-dän-dä-kyi sung-pa-la ngön-par tö-do //",
            english: "And highly praised what had been spoken by the Blessed One."
        ),

        PechaPage(
            id: "heart-dedication",
            section: .dedication,
            title: "Dedication",
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
            and conquer the enemy of faults and delusion.
            May they all be liberated from this ocean of samsara
            and from its pounding waves of birth, old age, sickness and death.
            """
        )
    ]
}
