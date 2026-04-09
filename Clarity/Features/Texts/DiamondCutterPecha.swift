import Foundation

enum DiamondCutterPecha {
    static let title = "Diamond-Cutter Wisdom"
    static let subtitle = "A fresh rendering"
    static let source = "Clarity working edition"

    static let pages: [PechaPage] = [
        PechaPage(
            id: "diamond-title",
            section: .title,
            title: "Diamond-Cutter Wisdom",
            tibetan: """
            ༄༅། །རྒྱ་གར་སྐད་དུ། ཨཱརྱ་བཛྲ་ཙྪིད་ཀནཱ་མ་པྲཛྙཱ་པཱ་ར་མི་ཏཱ་མ་ཧཱ་ཡཱ་ན་སཱུ་ཏྲ།
            བོད་སྐད་དུ། འཕགས་པ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་རྡོ་རྗེ་གཅོད་པ་ཞེས་བྱ་བ་ཐེག་པ་ཆེན་པོའི་མདོ།
            སངས་རྒྱས་དང་བྱང་ཆུབ་སེམས་དཔའ་ཐམས་ཅད་ལ་ཕྱག་འཚལ་ལོ། །
            """,
            english: "A fresh rendering"
        ),

        PechaPage(
            id: "diamond-opening-1",
            pageNumber: 1,
            section: .opening,
            tibetan: """
            འདི་སྐད་བདག་གིས་ཐོས་པ་དུས་གཅིག་ན། བཅོམ་ལྡན་འདས་མཉན་དུ་ཡོད་པ་ན་རྒྱལ་བུ་རྒྱལ་བྱེད་ཀྱི་ཚལ་མགོན་མེད་ཟས་སྦྱིན་གྱི་ཀུན་དགའ་ར་བ་ན།
            དགེ་སློང་སྟོང་ཉིས་བརྒྱ་ལྔ་བཅུའི་དགེ་སློང་གི་དགེ་འདུན་ཆེན་པོ་དང་།
            བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་རབ་ཏུ་མང་པོ་དང་ཐབས་ཅིག་ཏུ་བཞུགས་ཏེ།

            དེ་ནས་བཅོམ་ལྡན་འདས་སྔ་དྲོའི་དུས་ཀྱི་ཚེ་ཤམ་ཐབས་དང་ཆོས་གོས་བགོས་ཏེ། ལྷུང་བཟེད་བསྣམས་ནས། མཉན་ཡོད་ཀྱི་གྲོང་ཁྱེར་ཆེན་པོར་བསོད་སྙོམས་ཀྱི་ཕྱིར་ཞུགས་སོ། །

            དེ་ནས་བཅོམ་ལྡན་འདས་མཉན་ཡོད་ཀྱི་གྲོང་ཁྱེར་ཆེན་པོར་བསོད་སྙོམས་ཀྱི་ཕྱིར་གཤེགས་ནས་བསོད་སྙོམས་ཀྱི་ཞལ་ཟས་མཇུག་ཏུ་གསོལ་ཏེ། ཞལ་ཟས་ཀྱི་བྱ་བ་མཛད། ལྷུང་བཟེད་དང་ཆོས་གོས་བཞག་ནས། ཞལ་བསིལ་ཏེ། གདན་བཤམས་པ་ལ་སྐྱིལ་མོ་ཀྲུང་བཅས་ནས་སྐུ་དྲང་པོར་བསྲང་སྟེ། དྲན་པ་མངོན་དུ་བཞག་ནས་བཞུགས་སོ། །
            """,
            english: """
            This is what I heard.
            The Awakened One was staying at Shravasti, in Jeta’s Grove, in the park of Anathapindada, together with twelve hundred and fifty monks, and with a vast gathering of those on the path of awakening.

            At daybreak he put on his robe, took up his bowl, and went into Shravasti for alms.

            When he had gone through the city and eaten, he set the bowl and robe aside, washed his feet, prepared his seat, sat down, folded his legs, made the body upright, and settled into stillness.
            """
        ),

        PechaPage(
            id: "diamond-opening-2",
            pageNumber: 2,
            section: .opening,
            tibetan: """
            དེ་ནས་དགེ་སློང་མང་པོ་བཅོམ་ལྡན་འདས་ག་ལ་བ་དེར་དོང་ སྟེ་ལྷགས་ནས། བཅོམ་ལྡན་འདས་ཀྱི་ཞབས་ལ་མགོ་བོས་ཕྱག་འཚལ་ཏེ། བཅོམ་ལྡན་འདས་ལ་ལན་གསུམ་བསྐོར་བ་བྱས་ནས་ཕྱོགས་གཅིག་ཏུ་འཁོད་དོ། །ཡང་དེའི་ཚེ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་འཁོར་དེ་ཉིད་ན་འདུས་པར་གྱུར་ཏེ་འདུག་གོ། །

            དེ་ནས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་སྟན་ལས་ལངས་ཏེ། བླ་གོས་ཕྲག་པ་གཅིག་ཏུ་གཟར་ནས་པུས་མོ་གཡས་པའི་ལྷ་ང་ས་ལ་བཙུགས་ཏེ། བཅོམ་ལྡན་འདས་ག་ལ་བ་དེ་ལོགས་སུ་ཐལ་མོ་སྦྱར་བ་བཏུད་དེ། བཅོམ་ལྡན་འདས་ལ་འདི་སྐད་ཅེས་གསོལ་ཏོ། །

            བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་ སངས་རྒྱས་ཀྱིས་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་རྣམས་ལ་ཕན་གདགས་པའི་དམ་པ་ཇི་སྙེད་པས་ཕན་གདགས་པ་དང་། དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱིས་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་རྣམས་ལ་ཡོངས་སུ་གཏད་པའི་དམ་པ་ཇི་སྙེད་
            པས་ཡོངས་སུ་གཏད་པ་ནི་བཅོམ་ལྡན་འདས་ངོ་མཚར་ཏེ། བདེ་བར་གཤེགས་པ་ངོ་མཚར་ཏོ། །
            """,
            english: """
            The monks came forward, bowed, circled him, and sat to one side.

            Then Subhuti rose, bared one shoulder, knelt on his right knee, joined his palms, bowed, and said:

            “What the Awakened One has done for those who walk this great path is rare.
            What he has entrusted to them is rare.
            For those who truly enter this way -
            how should they stand?
            how should they train?
            how should they place the mind?”
            """
        ),

        PechaPage(
            id: "diamond-main-3",
            pageNumber: 3,
            section: .main,
            tibetan: """
            བཅོམ་ལྡན་འདས་བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་ཇི་ལྟར་གནས་པར་བགྱི། ཇི་ལྟར་བསྒྲུབ་པར་བགྱི། ཇི་ལྟར་སེམས་རབ་ཏུ་གཟུང་བར་བགྱི། དེ་སྐད་ཅེས་གསོལ་པ་དང་།

            བཅོམ་ལྡན་འདས་ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་བཀའ་སྩལ་ཏོ། །རབ་འབྱོར་ལེགས་སོ་ལེགས་སོ། །རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། དེ་བཞིན་གཤེགས་པས་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་རྣམས་ལ་ཕན་གདགས་པའི་དམ་པས་ཕན་བཏགས་སོ། ། དེ་བཞིན་གཤེགས་པས་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་རྣམས་ཡོངས་སུ་གཏད་པའི་དམ་པས་ཡོངས་སུ་གཏད་དོ། །

            རབ་འབྱོར་དེའི་ཕྱིར་ཉོན་ལ་ལེགས་པར་རབ་ཏུ་ཡིད་ལ་ཟུང་ཤིག་དང་། བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་ཇི་ལྟར་གནས་པར་བྱ་བ་དང་། ཇི་ལྟར་བསྒྲུབ་པར་བྱ་བ་དང་། ཇི་ལྟར་སེམས་རབ་ཏུ་གཟུང་བར་བྱ་བ་ངས་ཁྱོད་ལ་བཤད་དོ། །
            """,
            english: """
            The Awakened One said:

            “Good, Subhuti. Good.
            This is exactly the question.
            Listen carefully and hold it inwardly.
            I will show you how one on this path should stand, should train, and should place the mind.”

            Subhuti said, “Yes.”
            And he listened.
            """
        ),

        PechaPage(
            id: "diamond-main-4",
            pageNumber: 4,
            section: .main,
            tibetan: """
            བཅོམ་ལྡན་འདས་དེ་དེ་བཞིན་ནོ་ཞེས་གསོལ་ནས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་བཅོམ་ལྡན་འདས་ཀྱི་ལྟར་ཉན་པ་དང་། བཅོམ་ལྡན་འདས་ཀྱིས་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། །

            རབ་འབྱོར་འདི་ལ་བྱང་ཆུབ་ སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་འདི་སྙམ་དུ་བདག་གིས་ཅི་ཙམ་སེམས་ཅན་དུ་བསྡུ་བར་བསྡུས་པ་སྒོ་ང་ལས་སྐྱེས་པའམ། མངལ་ནས་སྐྱེས་པའམ། དྲོད་གཤེར་ལས་སྐྱེས་པའམ། བརྫུས་ཏེ་སྐྱེས་པའམ། གཟུགས་ཅན་ནམ། གཟུགས་མེད་པའམ། འདུ་ཤེས་ཅན་ནམ། འདུ་ཤེས་མེད་པའམ། འདུ་ཤེས་མེད་འདུ་ཤེས་མེད་མིན་ནམ། སེམས་ཅན་གྱི་ཁམས་ཇི་ཙམ་སེམས་ཅན་དུ་གདགས་པས་བཏགས་པ་དེ་དག་ཐམས་ཅད་ཕུང་པོའི་ལྷག་མ་མེད་པའི་མྱ་ངན་ལས་འདས་པའི་དབྱིངས་སུ་ཡོངས་སུ་མྱ་ངན་ལས་འདའོ། །
            """,
            english: """
            The Awakened One said:

            “When the mind of full awakening arises, this is how it should be placed:
            However many beings there are -
            born from eggs, from womb, from warmth and moisture, or appearing without such birth;
            with form, without form;
            with perception, without perception;
            beyond both perception and non-perception -
            all of them I will bring into complete release, into the peace beyond sorrow.
            """
        ),

        PechaPage(
            id: "diamond-main-5",
            pageNumber: 5,
            section: .main,
            tibetan: """
            དེ་ལྟར་སེམས་ཅན་ཚད་མེད་པ་ཡོངས་སུ་ མྱ་ངན་ལས་འདས་ཀྱང་སེམས་ཅན་གང་ཡང་ཡོངས་སུ་མྱ་ངན་ལས་འདས་པར་གྱུར་པ་མེད་དོ་སྙམ་དུ་སེམས་བསྐྱེད་པར་བྱའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གལ་ཏེ་བྱང་ཆུབ་སེམས་དཔའ་སེམས་ཅན་དུ་འདུ་ཤེས་འཇུག་ན། དེ་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་མི་བྱ་བའི་ཕྱིར་རོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་

            འབྱོར་གང་སེམས་ཅན་དུ་འདུ་ཤེས་འཇུག་གམ། སྲོག་ཏུ་འདུ་ཤེས་སམ། གང་ཟག་ཏུ་འདུ་ཤེས་འཇུག་ན་དེ་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་མི་བྱ་བའི་ཕྱིར་ཏེ། ཡང་རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔས་དངོས་པོ་ལ་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་ནོ། །ཆོས་ལ་ཡང་མི་གནས་པར་སྦྱིན་པ་ སྦྱིན་ནོ། །གཟུགས་ལའང་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་ནོ། །སྒྲ་དང་། དྲི་དང་། རོ་དང་། རེག་བྱ་དང་། ཆོས་ལ་ཡང་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་ནོ། །
            """,
            english: """
            And yet, even when limitless beings have been brought into complete release, no being at all has been brought into complete release.
            Why?
            Because if one on this path still takes hold of 'being',
            or 'life',
            or 'person',
            that one is not yet truly on this path.

            Subhuti, one on this path gives without landing anywhere.
            They give without fixing on any object.
            They give without fixing on what is seen.
            They give without fixing on sound, smell, taste, touch, or thought.
            """
        ),

        PechaPage(
            id: "diamond-main-6",
            pageNumber: 6,
            section: .main,
            tibetan: """
            རབ་འབྱོར་ཅི་ནས་མཚན་མར་འདུ་ཤེས་པ་ལའང་མི་གནས་པ་དེ་ལྟར་བྱང་ཆུབ་སེམས་དཔས་སྦྱིན་པ་སྦྱིན་ནོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན།

            རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་གང་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་པ་དེའི་བསོད་ནམས་ཀྱི་ཕུང་པོ་ནི་རབ་འབྱོར་ཚད་གཟུང་བར་སླ་བ་མ་ཡིན་པའི་ཕྱིར་རོ། །རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། ཤར་ཕྱོགས་ཀྱི་ནམ་མཁའ་ཚད་གཟུང་བར་སླའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། དེ་བཞིན་དུ་ལྷོ་དང་། ནུབ་དང་། བྱང་དང་། སྟེང་དང་། འོག་གི་ཕྱོགས་དང་། ཕྱོགས་མཚམས་དང་། ཕྱོགས་བཅུའི་ནམ་མཁའ་ཚད་གཟུང་བར་སླའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །
            """,
            english: """
            They give without making a sign out of anything.
            That is how giving is done.
            Why?
            Because the goodness gathered by giving in this way cannot be measured.

            Tell me, Subhuti - can the space to the east be measured?”
            Subhuti said, “No.”
            “Can the space to the south, west, north, above, below, or in any direction be measured?”
            “No.”
            """
        ),

        PechaPage(
            id: "diamond-main-7",
            pageNumber: 7,
            section: .main,
            tibetan: """
            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་བཞིན་དུ་བྱང་ཆུབ་སེམས་དཔའ་གང་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་པ་དེའི་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཡང་ཚད་གཟུང་བར་སླ་བ་མ་ཡིན་ནོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་བལྟའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ ནི་མ་ལགས་ཏེ། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་ལྟའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། དེ་བཞིན་གཤེགས་པས་མཚན་ཕུན་སུམ་ཚོགས་པར་གང་གསུངས་པ་དེ་ཉིད་མཚན་ཕུན་སུམ་ཚོགས་པ་མ་མཆིས་པའི་སླད་དུའོ། །

            དེ་སྐད་ཅེས་གསོལ་པ་དང་། བཅོམ་ལྡན་འདས་ ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། ། རབ་འབྱོར་ཅི་ཙམ་དུ་མཚན་ཕུན་སུམ་ཚོགས་པ་དེ་ཙམ་དུ་བརྫུན་ནོ། །ཅི་ཙམ་དུ་མཚན་ཕུན་སུམ་ཚོགས་པ་མེད་པ་དེ་ཙམ་དུ་མི་བརྫུན་ཏེ། དེ་ལྟར་དེ་བཞིན་གཤེགས་པ་ལ་མཚན་དང་། མཚན་མེད་པར་བལྟའོ། །
            """,
            english: """
            “In the same way, the goodness gathered by one who gives without fixing anywhere cannot be measured.

            Now tell me this, Subhuti -
            should the Awakened One be recognised by marks?”
            Subhuti said, “No.”
            The Awakened One said:
            “The marks are not what they seem.
            And because they are empty of anything solid, they are not false in the ordinary way either.
            So see the Awakened One where no mark can hold him.”
            """
        ),

        PechaPage(
            id: "diamond-main-8",
            pageNumber: 8,
            section: .main,
            tibetan: """
            དང་། བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་མ་འོངས་པའི་དུས་ལྔ་བརྒྱ་ཐ་མ་ལ་དམ་པའི་ཆོས་རབ་ཏུ་རྣམ་པར་འཇིག་པར་འགྱུར་བ་ན་སེམས་ཅན་གང་ལ་ལ་དག་འདི་ལྟ་བུའི་མདོ་སྡེའི་ཚིག་བཤད་པ་འདི་ལ་ཡང་དག་པར་འདུ་ཤེས་སྐྱེད་པར་འགྱུར་བ་ལྟ་མཆིས་སམ།

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་ཁྱོད་འདི་སྐད་དུ་མ་འོངས་པའི་དུས་ལྔ་བརྒྱ་ཐ་མ་ལ་དམ་པའི་ཆོས་རབ་ཏུ་རྣམ་པར་འཇིག་པར་འགྱུར་བ་ན་སེམས་ཅན་གང་ལ་ལ་དག་འདི་ལྟ་བུའི་མདོ་སྡེའི་ཚིག་བཤད་པ་འདི་ལ་ཡང་དག་པར་འདུ་ཤེས་སྐྱེད་པར་འགྱུར་བ་མཆིས་སམ་ཞེས་མ་ཟེར་ཅིག །

            ཡང་རབ་འབྱོར་མ་འོངས་པའི་དུས་ལྔ་བརྒྱ་ཐ་མ་ལ་དམ་པའི་ཆོས་རབ་ཏུ་རྣམ་པར་འཇིག་པར་འགྱུར་བ་ན་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་ཚུལ་ཁྲིམས་དང་ལྡན་པ། ཡོན་ཏན་དང་ལྡན་པ། ཤེས་རབ་དང་ལྡན་པ་དག་འབྱུང་སྟེ། རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་དག་ཀྱང་སངས་རྒྱས་གཅིག་ལ་བསྙེན་བཀུར་བྱས་པ་མ་ཡིན། སངས་རྒྱས་གཅིག་ལ་དགེ་བའི་རྩ་བ་བསྐྱེད་པ་མ་ཡིན་གྱི།
            """,
            english: """
            Then Subhuti asked:
            “In the later time, when the teaching is thinning out, will there be anyone who can truly receive words like these?”

            The Awakened One said:
            “Do not ask that.
            There will be such people.
            In that later time there will be those on this path who are steady in conduct, clear in heart, and deep in wisdom.
            They will not be people who have met only one awakened one and planted a little goodness there.
            """
        ),

        PechaPage(
            id: "diamond-main-9",
            pageNumber: 9,
            section: .main,
            tibetan: """
            རབ་འབྱོར་སངས་རྒྱས་བརྒྱ་སྟོང་དུ་མ་ལ་བསྙེན་བཀུར་བྱས་ཤིང་། སངས་རྒྱས་བརྒྱ་སྟོང་དུ་མ་ལ་དགེ་བའི་རྩ་བ་དག་བསྐྱེད་པའི་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་དག་འབྱུང་ངོ་། །གང་དག་འདི་ལྟ་བུའི་མདོ་སྡེའི་ཚིག་བཤད་པ་འདི་ལ་སེམས་དད་པ་ཅིག་ཙམ་རྙེད་པར་འགྱུར་བ་དེ་དག་ནི་རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་མཁྱེན་ཏོ། །རབ་འབྱོར་དེ་དག་ནི་དེ་བཞིན་གཤེགས་པས་གཟིགས་ཏེ། རབ་འབྱོར་སེམས་ཅན་དེ་དག་ཐམས་ཅད་ནི་བསོད་ནམས་ཀྱི་ཕུང་པོ་དཔག་ཏུ་མེད་པ་བསྐྱེད་ཅིང་རབ་ཏུ་སྡུད་པར་འགྱུར།

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་དེ་དག་ནི་བདག་ཏུ་འདུ་ཤེས་འཇུག་པར་མི་འགྱུར་ཞིང་སེམས་ཅན་དུ་འདུ་ཤེས་པ་མ་ཡིན། སྲོག་ཏུ་འདུ་ཤེས་པ་མ་ཡིན། གང་ཟག་ཏུའང་འདུ་ཤེས་འཇུག་པར་མི་འགྱུར་བའི་ཕྱིར་རོ། །རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་དེ་དག་ནི་ཆོས་སུ་འདུ་ཤེས་པ་དང་། ཆོས་མེད་པར་ཡང་འདུ་ཤེས་མི་འཇུག་སྟེ། དེ་དག་ནི་འདུ་ཤེས་དང་འདུ་ཤེས་མེད་པར་ཡང་འཇུག་པར་མི་འགྱུར་རོ། །
            """,
            english: """
            They will have honoured countless awakened ones and ripened deep roots through long familiarity with this way.
            If even one person hears words like these and a single clear pulse of trust arises, the Awakened One knows that one. He sees that one. The goodness opened there is beyond counting.

            Why?
            Because such people do not fall into the thought of a self, a being, a life, or a person.
            They do not fall into ‘this is a thing’.
            They do not fall into ‘this is not a thing’.
            They do not fall into ‘this is a thought’.
            They do not fall into ‘this is not a thought’.
            """
        ),

        PechaPage(
            id: "diamond-main-10",
            pageNumber: 10,
            section: .main,
            tibetan: """
            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གལ་ཏེ་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་དེ་དག་ཆོས་སུ་འདུ་ཤེས་འཇུག་ན་དེ་ཉིད་དེ་དག་གི་བདག་ཏུ་འཛིན་པར་འགྱུར་ཞིང་། སེམས་ཅན་དུ་འཛིན་པ་དང་། སྲོག་ཏུ་འཛིན་པ་དང་། གང་ཟག་ཏུ་འཛིན་པར་འགྱུར་བའི་ཕྱིར་རོ། །གལ་ཏེ་ཆོས་མེད་པར་འདུ་ཤེས་འཇུག་ན་ཡང་དེ་ཉིད་དེ་དག་གི་བདག་ཏུ་འཛིན་པར་འགྱུར་ཞིང་། སེམས་ཅན་དུ་འཛིན་པ་དང་། སྲོག་ཏུ་འཛིན་པ་དང་། གང་ཟག་ཏུ་འཛིན་པར་འགྱུར་བའི་ཕྱིར་རོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། ཡང་རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔས་ཆོས་ཀྱང་ལོག་པར་གཟུང་བར་མི་བྱ་སྟེ། ཆོས་མ་ཡིན་པ་ཡང་མི་གཟུང་བའི་ཕྱིར་རོ། །དེ་བས་ན་དེ་ལ་དགོངས་ཏེ། དེ་བཞིན་གཤེགས་པས་ཆོས་ཀྱི་རྣམ་གྲངས་གཟིངས་ལྟ་བུར་ཤེས་པ་རྣམས་ཀྱིས་ཆོས་རྣམས་ཀྱང་སྤང་བར་བྱ་ན་ཆོས་མ་ཡིན་པ་རྣམས་ལྟ་ཅི་སྨོས་ཞེས་གསུངས་སོ། །

            གཞན་ཡང་བཅོམ་ལྡན་འདས་ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། །རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། དེ་བཞིན་གཤེགས་པས་ཆོས་གང་ཡང་བསྟན་ཏམ།
            """,
            english: """
            Why?
            Because whenever the mind lands on anything at all, it quietly builds a self around it.
            And the same is true when it lands on no-thing.
            So do not seize the teaching wrongly.
            But do not seize ‘no teaching’ either.
            This is why it was said:
            A teaching is like a raft for crossing.
            Once crossed, even the raft is left behind.
            So how much more what was never the way at all.

            Now tell me, Subhuti -
            is there some fixed thing called unsurpassed full awakening that the Awakened One attained?
            Is there some fixed teaching that he teaches?”
            """
        ),

        PechaPage(
            id: "diamond-main-11",
            pageNumber: 11,
            section: .main,
            tibetan: """
            དེ་སྐད་ཅེས་བཀའ་སྩལ་ནས། བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་བཅོམ་ལྡན་འདས་ཀྱིས་གསུངས་པའི་དོན་བདག་གིས་འཚལ་བ་ལྟར་ན། དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཏུ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །དེ་བཞིན་གཤེགས་པས་གང་བསྟན་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །

            དེ་ཅིའི་སླད་དུ་ཞེ་ན། དེ་བཞིན་གཤེགས་པས་ཆོས་གང་ཡང་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའམ་བསྟན་པ་དེ་གཟུང་དུ་མ་མཆིས་བརྗོད་དུ་མ་མཆིས་ཏེ། དེ་ནི་ཆོས་ཀྱང་མ་ལགས། ཆོས་མ་མཆིས་པའང་མ་ལགས་པའི་སླད་དུའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། འཕགས་པའི་གང་ཟག་རྣམས་ནི་འདུས་མ་བགྱིས་ཀྱིས་རབ་ཏུ་ཕྱེ་བའི་སླད་དུའོ། །
            """,
            english: """
            Subhuti replied:
            “As I understand what has been said, no.
            There is no fixed thing called unsurpassed full awakening that was attained.
            And there is no fixed teaching that is taught.

            Why?
            Because what the Awakened One knows cannot be seized.
            It cannot be pinned down.
            It cannot finally be said to exist.
            It cannot finally be said not to exist.
            Those who are truly clear know by what is unborn.”
            """
        ),

        PechaPage(
            id: "diamond-main-12",
            pageNumber: 12,
            section: .main,
            tibetan: """
            བུའམ། རིགས་ཀྱི་བུ་མོ་གང་ལ་ལ་ཞིག་གིས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་འདི་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ་སྦྱིན་པ་བྱིན་ན། རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དེ་གཞི་དེ་ལས་བསོད་ནམས་ཀྱི་ཕུང་པོ་མང་དུ་བསྐྱེད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་མང་ལགས་སོ། །བདེ་བར་གཤེགས་པ་མང་ལགས་ཏེ། རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དེ་གཞི་དེ་ལས་བསོད་ནམས་ཀྱི་ཕུང་པོ་མང་དུ་བསྐྱེད་དོ། །

            དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་བསོད་ནམས་ཀྱི་ཕུང་པོ་དེ་ཉིད་ཕུང་པོ་མ་མཆིས་པའི་སླད་དུ་སྟེ། དེས་ན་དེ་བཞིན་གཤེགས་པས་བསོད་ནམས་ཀྱི་ཕུང་པོ་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཞེས་གསུངས་སོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་གིས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་འདི་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ་སྦྱིན་པ་བྱིན་པ་བས། གང་གིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་གཅིག་ཙམ་བཟུང་ནས་གཞན་དག་ལ་ཡང་འཆད་ཅིང་ཡང་དག་པར་རབ་ཏུ་སྟོན་ན། དེ་གཞི་དེ་ལས་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཆེས་མང་དུ་གྲངས་མེད་དཔག་ཏུ་མེད་པ་བསྐྱེད་དོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱི་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ནི་འདི་ལས་བྱུང་སྟེ། སངས་རྒྱས་བཅོམ་ལྡན་འདས་རྣམས་ཀྱང་འདི་ལས་སྐྱེས་པའི་ཕྱིར་རོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་སངས་རྒྱས་ཀྱི་ཆོས་རྣམས་སངས་རྒྱས་ཀྱི་ཆོས་རྣམས་ཞེས་བྱ་བ་ནི་སངས་རྒྱས་ཀྱི་ཆོས་དེ་དག་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་སངས་རྒྱས་ཀྱི་ཆོས་རྣམས་ཞེས་བྱའོ། །
            """,
            english: """
            Then the Awakened One said:
            “Suppose someone filled a thousand-million world-system with the seven precious things and offered it all away. Would much goodness come from that?”
            Subhuti said, “Yes. Very much.”

            The Awakened One said:
            “And yet, if someone held even four lines from this teaching, explained them clearly, and passed them on well, the goodness from that would be far greater.
            Why?
            Because from this comes the awakening of all buddhas.
            From this they are born.
            And what are called ‘the qualities of a buddha’ - those too are only spoken of that way because no fixed thing can be found there.”
            """
        ),

        PechaPage(
            id: "diamond-main-13",
            pageNumber: 13,
            section: .main,
            tibetan: """
            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། རྒྱུན་དུ་ཞུགས་པ་འདི་སྙམ་དུ་བདག་གིས་རྒྱུན་དུ་ཞུགས་པའི་འབྲས་བུ་ཐོབ་བོ་སྙམ་དུ་སེམས་སམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་དེ་ཅི་ལའང་ཞུགས་པ་མ་མཆིས་པའི་སླད་དུ་སྟེ། དེས་ན་རྒྱུན་དུ་ཞུགས་པ་ཞེས་བྱའོ། །གཟུགས་ལའང་མ་ཞུགས། སྒྲ་ལ་མ་ལགས། དྲི་ལ་མ་ལགས། རོ་ལ་མ་ལགས། རེག་བྱ་ལ་མ་ལགས། ཆོས་
            """,
            english: """
            Now tell me, Subhuti -
            would someone who has entered the current think, ‘I have entered the current’?”
            Subhuti said, “No.”
            “Why not?”
            “Because there is nowhere to enter.
            Not form.
            Not sound.
            Not smell.
            Not taste.
            Not touch.
            Not thought.
            That is why it is called entering the current.
            If such a one thought, ‘I have entered’, that very thought would already be grasping at self, being, life, and person.”
            """
        ),

        PechaPage(
            id: "diamond-main-14",
            pageNumber: 14,
            section: .main,
            tibetan: """
            ལ་འང་མ་ཞུགས་ཏེ། དེས་ན་རྒྱུན་དུ་ཞུགས་པ་ཞེས་བགྱིའོ། །བཅོམ་ལྡན་འདས་གལ་ཏེ་རྒྱུན་དུ་ཞུགས་པ་དེ་འདི་སྙམ་དུ་བདག་གིས་རྒྱུན་དུ་ཞུགས་པའི་འབྲས་བུ་ཐོབ་བོ་སྙམ་དུ་སེམས་པར་གྱུར་ན་དེ་ཉིད་དེའི་བདག་ཏུ་འཛིན་པར་འགྱུར་རོ། །སེམས་ཅན་དུ་འཛིན་པ་དང་། སྲོག་ཏུ་འཛིན་པ་དང་། གང་ཟག་ཏུ་འཛིན་པར་འགྱུར་རོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། ལན་ཅིག་ཕྱིར་འོང་བ་འདི་སྙམ་དུ་བདག་གིས་ལན་ཅིག་ཕྱིར་འོང་བའི་འབྲས་བུ་ཐོབ་བོ་སྙམ་དུ་སེམས་སམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། གང་ལན་ཅིག་ཕྱིར་འོང་བའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་པའི་སླད་དུ་སྟེ། དེས་ན་ལན་ཅིག་ཕྱིར་འོང་བ་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་ཇི་སྙམ་དུ་སེམས། ཕྱིར་མི་འོང་བ་འདི་སྙམ་དུ་བདག་གིས་ཕྱིར་མི་འོང་བའི་འབྲས་བུ་ཐོབ་བོ་སྙམ་དུ་སེམས་སམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། གང་ཕྱིར་མི་འོང་བ་ཉིད་དུ་ཞུགས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་པའི་སླད་དུ་སྟེ། དེས་ན་ཕྱིར་མི་འོང་བ་ཞེས་བགྱིའོ། །
            """,
            english: """
            And if one who has entered the current were to think, ‘I have entered the current,’ that very thought would already be grasping at self, being, life, and person.

            The Awakened One said:
            “And would one who comes back once think, ‘I have reached the state of returning once’?”
            Subhuti said, “No.
            Because no fixed state can be found there either.
            That is why it is called returning once.”

            “And would one who does not return think, ‘I have reached the state of not returning’?”
            “No.
            Because no fixed state can be found there either.
            That is why it is called not returning.”
            """
        ),

        PechaPage(
            id: "diamond-main-15",
            pageNumber: 15,
            section: .main,
            tibetan: """
            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། ཡང་དགྲ་བཅོམ་པ་འདི་སྙམ་དུ་བདག་གིས་དགྲ་བཅོམ་པ་ཉིད་ཐོབ་བོ་སྙམ་དུ་སེམས་སམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། གང་དགྲ་བཅོམ་པ་ཞེས་བགྱི་བའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་པའི་སླད་དུའོ། །

            བཅོམ་ལྡན་འདས་གལ་ཏེ་དགྲ་བཅོམ་པ་འདི་སྙམ་དུ་བདག་གིས་དགྲ་བཅོམ་པ་ཉིད་ཐོབ་བོ་སྙམ་དུ་སེམས་པར་གྱུར་ན་དེ་ཉིད་དེའི་བདག་ཏུ་འཛིན་པར་འགྱུར་རོ། །སེམས་ཅན་དུ་འཛིན་པ་དང་། སྲོག་ཏུ་འཛིན་པ་དང་། གང་ཟག་ཏུ་འཛིན་པར་འགྱུར་རོ། །བཅོམ་ལྡན་འདས་བདག་ནི་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱིས་ཉོན་མོངས་པ་མེད་པར་གནས་པ་རྣམས་ཀྱི་མཆོག་ཏུ་བསྟན་ཏེ། བཅོམ་ལྡན་འདས་བདག་འདོད་ཆགས་དང་བྲལ་བ་དགྲ་བཅོམ་པ་ལགས་ཀྱང་།
            """,
            english: """
            The Awakened One said:
            “And would one who is free of the afflictions think, ‘I am free’?”
            Subhuti said:
            “No.
            If such a one thought, ‘I am free,’ that thought itself would still be binding.
            That is why freedom is spoken of only where nothing is being claimed.”

            The Blessed One has declared me foremost among those who dwell without affliction.
            It is true that I am free from craving.
            """
        ),

        PechaPage(
            id: "diamond-main-16",
            pageNumber: 16,
            section: .main,
            tibetan: """
            བཅོམ་པའོ་སྙམ་དུ་མི་སེམས་སོ། །བཅོམ་ལྡན་འདས་གལ་ཏེ་བདག་ནི་འདི་སྙམ་དུ་བདག་གིས་དགྲ་བཅོམ་པ་ཉིད་ཐོབ་བོ་སྙམ་དུ་སེམས་པར་གྱུར་ན། དེ་བཞིན་གཤེགས་པས་བདག་ལ་རིགས་ཀྱི་བུ་རབ་འབྱོར་ནི་ཉོན་མོངས་པ་མེད་པར་གནས་པ་རྣམས་ཀྱི་མཆོག་ཡིན་ཏེ། ཅི་ལ་ཡང་མི་གནས་པས་ན་ ཉོན་མོངས་པ་མེད་པར་གནས་པ་ཉོན་མོངས་པ་མེད་པར་གནས་པ་ཞེས་ལུང་མི་སྟོན་ཏོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་མར་མེ་མཛད་ལས་གང་བླངས་པའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་ཏེ། དེ་བཞིན་གཤེགས་པས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་མར་མེ་མཛད་ལས་གང་བླངས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་གང་ལ་ལ་ཞིག་འདི་སྐད་དུ་བདག་གིས་ཞིང་བཀོད་པ་རྣམས་བསྒྲུབ་པར་བྱའོ་ཞེས་ཟེར་ན་དེ་ནི་མི་བདེན་པར་སྨྲ་བའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་ཞིང་བཀོད་པ་རྣམས་ཞིང་བཀོད་པ་རྣམས་ཞེས་བྱ་བ་ནི་བཀོད་པ་དེ་དག་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་ཞིང་བཀོད་པ་རྣམས་ཞེས་བྱའོ། །
            """,
            english: """
            Yet I do not think, ‘I am an arhat.’
            If I did think that, the Awakened One would not have declared of me, ‘Subhuti is foremost among those who dwell without affliction,’ because that very thought would mean I was still abiding in something.

            Then the Awakened One said:
            “What do you think, Subhuti? Did the Tathagata receive any fixed dharma from Dipankara Buddha?”
            Subhuti said, “No. No fixed dharma was received.”

            The Awakened One said:
            “If a bodhisattva were to say, ‘I will establish perfect buddha-fields,’ that would not be true.
            Why?
            Because what are called buddha-fields are spoken of that way precisely because no fixed field can be found there.”
            """
        ),

        PechaPage(
            id: "diamond-main-17",
            pageNumber: 17,
            section: .main,
            tibetan: """
            རབ་འབྱོར་དེ་ལྟ་བས་ན་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོས་འདི་ལྟར་མི་གནས་པར་སེམས་བསྐྱེད་པ་ཞེས་བྱའོ། །ཅི་ལ་ཡང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །གཟུགས་ལ་ཡང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། ། སྒྲ་དང་། དྲི་དང་། རོ་དང་། རེག་བྱ་དང་། ཆོས་ལ་ཡང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །

            རབ་འབྱོར་འདི་ལྟ་སྟེ་དཔེར་ན་སྐྱེས་བུ་ཞིག་ལུས་འདི་ལྟ་བུར་གྱུར་ཏེ། འདི་ལྟ་སྟེ། རིའི་རྒྱལ་པོ་རི་རབ་ཙམ་དུ་གྱུར་ན་རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། ལུས་དེ་ཆེ་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་ལུས་དེ་ནི་ཆེ་བ་ལགས་སོ། །བདེ་བར་གཤེགས་པ་ལུས་དེ་ཆེ་བ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། དེ་བཞིན་གཤེགས་པས་དེ་དངོས་པོ་མ་མཆིས་པར་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་ལུས་ཞེས་བགྱིའོ། །དེ་དངོས་པོ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ།
            """,
            english: """
            Therefore the bodhisattva should give rise to mind without abiding anywhere.
            Without abiding in form.
            Without abiding in sound, smell, taste, touch, or thought.

            Suppose, Subhuti, a person had a body as vast as Mount Meru, the king of mountains.
            Would that body be great?”
            Subhuti replied, “Yes. Very great.
            Yet it is called a body only because, as the Tathagata teaches, no fixed thing can be found there.”
            """
        ),

        PechaPage(
            id: "diamond-main-18",
            pageNumber: 18,
            section: .main,
            tibetan: """
            ཞེས་བགྱིའོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། གང་གཱའི་ཀླུང་གི་བྱེ་མ་ཇི་སྙེད་པ་གང་གཱའི་ཀླུང་ཡང་དེ་སྙེད་ཁོ་ནར་གྱུར་ན་དེ་དག་གི་བྱེ་མ་གང་ཡིན་པ་དེ་མང་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་གང་གཱའི་ཀླུང་དེ་དག་ཉིད་ཀྱང་མང་བ་ལགས་ན་དེ་དག་གི་བྱེ་མ་ལྟ་སྨོས་ཀྱང་ཅི་འཚལ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་ཁྱོད་ཀྱིས་མོས་པར་བྱ། ཁྱོད་ཀྱིས་ཁོང་དུ་ཆུད་པར་བྱའོ། །གང་གཱའི་ཀླུང་དེ་དག་གི་བྱེ་མ་ཇི་སྙེད་པ་དེ་སྙེད་ཀྱི་འཇིག་རྟེན་གྱི་ཁམས་སྐྱེས་པའམ། བུད་མེད་གང་ལ་ལ་ཞིག་གིས་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ། དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་རྣམས་ལ་སྦྱིན་པ་བྱིན་ན། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། སྐྱེས་པའམ་བུད་མེད་དེ་གཞི་དེ་ལས་བསོད་ནམས་མང་དུ་སྐྱེད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་མང་ལགས་སོ། །བདེ་བར་གཤེགས་པ་མང་ལགས་ཏེ། སྐྱེས་པའམ་བུད་མེད་དེ་གཞི་དེ་ལས་བསོད་ནམས་མང་དུ་སྐྱེད་དོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་གང་གིས་འཇིག་རྟེན་གྱི་ཁམས་དེ་སྙེད་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ། དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་རྣམས་ལ་སྦྱིན་པ་བྱིན་པ་བས། གང་གིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་བཟུང་ནས་གཞན་དག་ལ་ཡང་རྒྱ་ཆེར་ཡང་དག་པར་རབ་ཏུ་བསྟན་ན། དེ་ཉིད་གཞི་དེ་ལས་བསོད་ནམས་ཆེས་མང་དུ་གྲངས་མེད་དཔག་ཏུ་མེད་པ་བསྐྱེད་དོ། །

            ཡང་རབ་འབྱོར་ས་ཕྱོགས་གང་ན་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་འདོན་ཏམ་སྟོན་པའི་ས་ཕྱོགས་དེ་ལྷ་དང་མི་དང་ལྷ་མ་ཡིན་དུ་བཅས་པའི་འཇིག་རྟེན་གྱི་མཆོད་རྟེན་དུ་གྱུར་པ་ཡིན་ན། སུ་ཞིག་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་པ་དང་། ཚུལ་བཞིན་དུ་ཡིད་ལ་བྱེད་པ་དེ་ངོ་མཚར་རབ་དང་ལྡན་པར་འགྱུར་བ་ལྟ་ཅི་སྨོས། ས་ཕྱོགས་དེ་ན་སྟོན་པ་ཡང་བཞུགས་ཏེ། བླ་མའི་གནས་གཞན་དག་ཀྱང་གནས་སོ། །
            """,
            english: """
            The Awakened One said:
            “Suppose there were as many Ganges rivers as grains of sand in the Ganges, and each of those rivers had its own sands beyond counting.
            If someone filled all those world-systems with the seven precious things and offered them to the buddhas, would much goodness come from that?”
            Subhuti said, “Very much.”

            The Awakened One said:
            “And yet if someone took even four lines from this teaching, received them, held them, recited them, understood them well, and explained them widely and truly to others, the goodness from that would far surpass the former.

            Wherever even four lines of this teaching are recited or taught, that place becomes like a shrine for gods, humans, and all beings.
            How much more so where someone receives it, holds it, reads it, and contemplates it rightly.
            In such a place, the Teacher is present, and the noble lineage remains.”
            """
        ),

        PechaPage(
            id: "diamond-main-19",
            pageNumber: 19,
            section: .main,
            tibetan: """
            གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་ཆོས་ཀྱི་རྣམ་གྲངས་འདིའི་མིང་ཅི་ལགས། ཇི་ལྟར་གཟུང་བར་བགྱི། དེ་སྐད་ཅེས་གསོལ་པ་དང་། བཅོམ་ལྡན་འདས་ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། །རབ་འབྱོར་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཞེས་བྱ་སྟེ། འདི་དེ་ལྟར་ཟུང་ཞིག །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་གང་བཟུང་བ་དེ་ཉིད་ཕ་རོལ་ཏུ་ཕྱིན་པ་མེད་པའི་ཕྱིར་ཏེ། དེས་ན་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་ཞེས་བྱའོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པས་གང་གསུངས་པའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པས་གང་གསུངས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་ན་སའི་རྡུལ་ཕྲ་རབ་ཇི་སྙེད་ཡོད་པ་དེ་མང་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་སའི་རྡུལ་དེ་མང་ལགས་སོ། །བདེ་བར་གཤེགས་པ་མང་ལགས་སོ། །

            དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་སའི་རྡུལ་གང་ལགས་པ་དེ་རྡུལ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་སའི་རྡུལ་ཅེས་བགྱིའོ། །འཇིག་རྟེན་གྱི་ཁམས་གང་ལགས་པ་དེ་ཁམས་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ། དེས་ན་འཇིག་རྟེན་གྱི་ཁམས་ཞེས་བྱའོ། །
            """,
            english: """
            Then Subhuti asked:
            “What is the name of this teaching, Blessed One, and how should it be held?”

            The Blessed One said:
            “This teaching is called the Perfection of Wisdom. Hold it in that way.
            Why?
            Because what the Tathagata calls the Perfection of Wisdom is spoken of that way precisely because no fixed perfection can be found there.

            And what do you think, Subhuti? Is there any fixed dharma that the Tathagata has taught?”
            Subhuti said, “No.”

            The Blessed One said:
            “And what do you think? Are the dust motes in a great three-thousandfold world-system many?”
            Subhuti said, “Very many.”
            Yet they are called dust motes only because, as the Tathagata teaches, no fixed mote can be found there.
            The same is true of a world-system.”
            """
        ),

        PechaPage(
            id: "diamond-main-20",
            pageNumber: 20,
            section: .main,
            tibetan: """
            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། སྐྱེས་བུ་ཆེན་པོའི་མཚན་སུམ་ཅུ་རྩ་གཉིས་པོ་དེ་དག་གིས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་སུ་ལྟའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། སྐྱེས་བུ་ཆེན་པོའི་མཚན་སུམ་ཅུ་རྩ་གཉིས་པོ་གང་དག་དེ་བཞིན་གཤེགས་པས་གསུངས་པ་དེ་དག་མཚན་མ་མཆིས་པར་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་དེ་བཞིན་གཤེགས་པའི་མཚན་སུམ་ཅུ་རྩ་གཉིས་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། ཡང་རབ་འབྱོར་སྐྱེས་པའམ། བུད་མེད་གང་གིས་ལུས་གང་གཱའི་ཀླུང་གི་བྱེ་མ་སྙེད་ཡོངས་སུ་གཏོང་བ་བས་གང་གིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་བཟུང་སྟེ། གཞན་དག་
            """,
            english: """
            The Blessed One said:
            “What do you think, Subhuti? Can the Tathagata be seen by means of the thirty-two marks of a great being?”
            Subhuti said, “No.
            Why?
            Because what the Tathagata calls the thirty-two marks are spoken of that way precisely because no fixed marks can be found there.”

            And the Blessed One said:
            “If a man or woman were to give up as many bodies as there are grains of sand in the Ganges, and another were to take even four lines from this teaching, hold them, and pass them on to others...”
            """
        ),

        PechaPage(
            id: "diamond-main-21",
            pageNumber: 21,
            section: .main,
            tibetan: """
            ལ་ཡང་བསྟན་ན་དེ་གཞི་དེ་ལས་བསོད་ནམས་ཆེས་མང་དུ་གྲངས་མེད་དཔག་ཏུ་མེད་པ་བསྐྱེད་དོ། །དེ་ནས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ཆོས་ཀྱི་ཤུགས་ཀྱིས་མཆི་མ་ཕྱུང་སྟེ། དེས་མཆི་མ་ཕྱིས་ནས་བཅོམ་ལྡན་འདས་ལ་འདི་སྐད་ཅེས་གསོལ་ཏོ། །འདི་ལྟར་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་དེ་བཞིན་གཤེགས་པས་གསུངས་པ་ནི་བཅོམ་ལྡན་འདས་ངོ་མཚར་ཏོ། །བདེ་བར་གཤེགས་པ་ངོ་མཚར་ཏོ། །བཅོམ་ལྡན་འདས་བདག་གི་ཡེ་ཤེས་སྐྱེས་ཚུན་ཆད་བདག་གིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་སྔོན་ནམ་ཡང་མ་ཐོས་སོ། །

            བཅོམ་ལྡན་འདས་མདོ་བཤད་པ་འདི་ལ་གང་དག་ཡང་དག་པར་འདུ་ཤེས་བསྐྱེད་པར་གྱུར་པའི་སེམས་ཅན་དེ་དག་ནི་ངོ་མཚར་རབ་དང་ལྡན་པར་འགྱུར་རོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་ཡང་དག་པར་འདུ་ཤེས་པ་གང་ལགས་པ་དེ་ཉིད་འདུ་ཤེས་མ་མཆིས་པའི་སླད་དུ་སྟེ། དེ་བས་ན་ཡང་དག་པར་འདུ་ཤེས་ཡང་དག་པར་འདུ་ཤེས་ཞེས་དེ་བཞིན་གཤེགས་པས་གསུངས་སོ། །

            བཅོམ་ལྡན་འདས་བདག་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་བཤད་པ་ལ་རྟོག་ཅིང་མོས་པ་ནི་བདག་ལ་མོས་པ་མ་ལགས་ཀྱི། བཅོམ་ལྡན་འདས་སླད་མའི་ཚེ་སླད་མའི་དུས་ལྔ་བརྒྱ་པ་ཐ་མ་ལ་སེམས་ཅན་གང་དག་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བགྱིད་པ་དེ་དག་ནི་ངོ་མཚར་རབ་དང་ལྡན་པར་འགྱུར་རོ། །

            ཡང་བཅོམ་ལྡན་འདས་དེ་དག་ནི་བདག་ཏུ་འདུ་ཤེས་འཇུག་པར་མི་འགྱུར། སེམས་ཅན་དུ་འདུ་ཤེས་པ་དང་། སྲོག་ཏུ་འདུ་ཤེས་པ་དང་། གང་ཟག་ཏུ་འདུ་ཤེས་འཇུག་པར་མི་འགྱུར་ལགས་སོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་བདག་ཏུ་འདུ་ཤེས་པ་དང་། སེམས་ཅན་དུ་འདུ་ཤེས་པ་དང་། སྲོག་ཏུ་འདུ་ཤེས་པ་དང་། གང་ཟག་ཏུ་འདུ་ཤེས་པ་གང་ལགས་པ་དེ་དག་ཉིད་འདུ་ཤེས་མ་མཆིས་པའི་སླད་དུའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། སངས་རྒྱས་བཅོམ་ལྡན་འདས་རྣམས་ནི་འདུ་ཤེས་ཐམས་ཅད་དང་བྲལ་བའི་སླད་དུའོ། །

            དེ་སྐད་ཅེས་གསོལ་པ་དང་། བཅོམ་ལྡན་འདས་ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། །རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། མདོ་བཤད་པ་འདི་ལ་གང་དག་མི་སྐྲག་མི་དངང་ཞིང་དངང་བར་མི་འགྱུར་བའི་སེམས་ཅན་དེ་དག་ནི་ངོ་མཚར་རབ་དང་ལྡན་པར་འགྱུར་རོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། རབ་འབྱོར་ཕ་རོལ་ཏུ་ཕྱིན་པ་དམ་པ་འདི་ནི་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ།
            """,
            english: """
            …and explained it to others, the goodness from that would be vastly greater.

            Then Subhuti, moved by the force of the Dharma, wept. Wiping away his tears, he said:
            “Wonderful, Blessed One. Wonderful.
            Since wisdom first awakened in me, I have never before heard a teaching like this.
            Those who can receive this sutra with right understanding will be truly extraordinary.

            Why?
            Because what is called right understanding is spoken of that way only because no fixed understanding can be found there.

            As for me, to hear this teaching, reflect on it, and trust it is not difficult.
            But in the later time, in the final five hundred years, those who receive it, hold it, read it, internalize it, and live by it will be truly extraordinary.
            They will not fall into self, being, life, or person.
            For all buddhas are free from every fixed perception.”

            The Blessed One said:
            “Yes, Subhuti. Exactly so.
            Those who are not frightened, alarmed, or shaken by this sutra are truly extraordinary.”
            """
        ),

        PechaPage(
            id: "diamond-main-22",
            pageNumber: 22,
            section: .main,
            tibetan: """
            གསུངས་པ་དེ་སངས་རྒྱས་བཅོམ་ལྡན་འདས་དཔག་ཏུ་མེད་པ་རྣམས་ཀྱིས་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་ཕ་རོལ་ཏུ་ཕྱིན་པ་དམ་པ་ཞེས་བྱའོ། །ཡང་རབ་འབྱོར་དེ་བཞིན་གཤེགས་པའི་བཟོད་པའི་ཕ་རོལ་ཏུ་ཕྱིན་པ་གང་ཡིན་པ་དེ་ཉིད་ཕ་རོལ་ཏུ་ཕྱིན་པ་མེད་དོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གང་གི་ཚེ་ཀ་ལིང་ཀཱའི་རྒྱལ་པོས་ངའི་ཡན་ལག་དང་ཉིང་ལག་རྣམས་བཅད་པར་གྱུར་པ་དེའི་ཚེ་ང་ལ་བདག་ཏུ་འདུ་ཤེས་སམ། སེམས་ཅན་དུ་འདུ་ཤེས་སམ། སྲོག་ཏུ་འདུ་ཤེས་སམ། གང་ཟག་ཏུ་འདུ་ཤེས་ཀྱང་མ་བྱུང་ལ། ང་ལ་འདུ་ཤེས་ཅིའང་མེད་ལ་འདུ་ཤེས་མེད་པར་གྱུར་པ་ཡང་མ་ཡིན་པའི་ཕྱིར་རོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གལ་ཏེ་དེའི་ཚེ་ང་ལ་བདག་ཏུ་འདུ་ཤེས་བྱུང་ན་དེའི་ཚེ་གནོད་སེམས་ཀྱི་འདུ་ཤེས་ཀྱང་བྱུང་ལ། སེམས་ཅན་དུ་འདུ་ཤེས་པ་དང་། སྲོག་ཏུ་འདུ་ཤེས་པ་དང་། གང་ཟག་ཏུ་འདུ་ཤེས་བྱུང་ན་དེའི་ཚེ་གནོད་སེམས་ཀྱི་འདུ་ཤེས་ཀྱང་འབྱུང་བའི་ཕྱིར་རོ། །

            རབ་འབྱོར་ངས་མངོན་པར་ཤེས་ཏེ། འདས་པའི་དུས་ན་ང་ཚེ་རབས་ལྔ་བརྒྱར་བཟོད་པར་སྨྲ་བ་ཞེས་བྱ་བའི་དྲང་སྲོང་དུ་གྱུར་པ་དེ་ན་ཡང་ང་ལ་བདག་ཏུ་འདུ་ཤེས་མ་བྱུང་། སེམས་ཅན་དུ་འདུ་ཤེས་པ་དང་། སྲོག་ཏུ་འདུ་ཤེས་པ་དང་། གང་ཟག་ཏུ་འདུ་ཤེས་མ་བྱུང་ངོ་། །
            """,
            english: """
            The perfection spoken here has been spoken by innumerable buddhas; that is why it is called the supreme perfection.

            And again, Subhuti, what the Tathagata calls the perfection of patience is spoken of that way precisely because no fixed perfection can be found there.

            Why?
            When the King of Kalinga cut away my limbs and body, no perception of self, being, life, or person arose in me. Nor did I fall into some blankness without perception.

            If at that time I had held any thought of self, being, life, or person, then a thought of harm and anger would also have arisen.

            I know this clearly, Subhuti: in five hundred former lives, when I lived as a rishi called “Speaker of Patience,” no thought of self, being, life, or person arose in me there either.
            """
        ),

        PechaPage(
            id: "diamond-main-23",
            pageNumber: 23,
            section: .main,
            tibetan: """
            རབ་འབྱོར་དེ་ལྟ་བས་ན་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོས་འདུ་ཤེས་ཐམས་ཅད་རྣམ་པར་སྤངས་ཏེ་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཏུ་སེམས་བསྐྱེད་པར་བྱའོ། །གཟུགས་ལ་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །སྒྲ་དང་། དྲི་དང་། རོ་དང་། རེག་བྱ་དང་། ཆོས་ལའང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །ཆོས་མེད་པ་ལའང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །ཅི་ལའང་མི་གནས་པར་སེམས་བསྐྱེད་པར་བྱའོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། གནས་པ་གང་ཡིན་པ་དེ་ཉིད་མི་གནས་པའི་ཕྱིར་ཏེ། དེ་བས་ན་དེ་བཞིན་གཤེགས་པས་འདི་སྐད་དུ། བྱང་ཆུབ་སེམས་དཔས་མི་གནས་པར་སྦྱིན་པ་སྦྱིན་པར་བྱའོ་ཞེས་གསུངས་སོ། །

            ཡང་རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔས་འདི་ལྟར་སེམས་ཅན་ཐམས་ཅད་ཀྱི་དོན་གྱི་ཕྱིར་སྦྱིན་པ་ཡོངས་སུ་གཏང་བར་བྱའོ། །སེམས་ཅན་དུ་འདུ་ཤེས་པ་གང་ཡིན་པ་དེ་ཉིད་ཀྱང་འདུ་ཤེས་མེད་པ་སྟེ། དེ་བཞིན་གཤེགས་པས་སེམས་ཅན་ཐམས་ཅད་ཅེས་གང་གསུངས་པ་དེ་ཉིད་ཀྱང་མེད་པའོ། །
            """,
            english: """
            Therefore, Subhuti, the great bodhisattva should cast away every fixation and give rise to unsurpassed perfect awakening.
            Without abiding in form.
            Without abiding in sound, smell, taste, touch, or thought.
            Without abiding even in “no dharmas.”
            Without abiding anywhere at all.

            Why?
            Because whatever is called abiding is, in truth, non-abiding.
            That is why the Tathagata says that the bodhisattva should give without abiding.

            And again, Subhuti, the bodhisattva should give for the welfare of all beings.
            Yet what is taken to be “beings” is itself no fixed perception.
            When the Tathagata speaks of “all beings,” those too are not truly found.
            """
        ),

        PechaPage(
            id: "diamond-main-24",
            pageNumber: 24,
            section: .main,
            tibetan: """
            པ་གསུང་བ། དེ་བཞིན་ཉིད་གསུང་བ་སྟེ། དེ་བཞིན་གཤེགས་པ་ནི་མ་ནོར་བ་དེ་བཞིན་ཉིད་གསུང་བའི་ཕྱིར་རོ། །ཡང་རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་ཆོས་གང་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའམ་བསྟེན་པ་དེ་ལ་ནི་བདེན་པ་ཡང་མེད་བརྫུན་པ་ཡང་མེད་དོ། །

            རབ་འབྱོར་འདི་ལྟ་སྟེ་དཔེར་ན་མིག་དང་ལྡན་པའི་མི་ཞིག་མུན་པར་ཞུགས་ནས་ཅི་ཡང་མི་མཐོང་བ་དེ་བཞིན་དུ་གང་དངོས་པོར་ལྷུང་བས་སྦྱིན་པ་ཡོངས་སུ་གཏོང་བའི་བྱང་ཆུབ་སེམས་དཔར་བལྟའོ། །རབ་འབྱོར་འདི་ལྟ་སྟེ་དཔེར་ན་ནམ་ལངས་ཏེ་ཉི་མ་ཤར་ན་མིག་དང་ལྡན་པའི་མིས་གཟུགས་རྣམ་པ་སྣ་ཚོགས་དག་མཐོང་བ་དེ་བཞིན་དུ། གང་དངོས་པོར་མ་ལྷུང་བས་སྦྱིན་པ་ཡོངས་སུ་གཏོང་བའི་བྱང་ཆུབ་སེམས་དཔར་བལྟའོ། །

            ཡང་རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་དག་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་པ་དང་། གཞན་དག་ལ་ཡང་རྒྱ་ཆེར་ཡང་དག་པར་རབ་ཏུ་སྟོན་པ་དེ་དག་ནི་དེ་བཞིན་གཤེགས་པས་མཁྱེན། དེ་དག་ནི་དེ་བཞིན་གཤེགས་པས་གཟིགས་ཏེ། སེམས་ཅན་དེ་དག་ཐམས་ཅད་ནི་བསོད་ནམས་ཀྱི་ཕུང་པོ་དཔག་ཏུ་མེད་པ་བསྐྱེད་པར་འགྱུར་རོ། །

            ཡང་རབ་འབྱོར་སྐྱེས་པའམ་བུད་མེད་གང་ཞིག་སྔ་དྲོའི་དུས་ཀྱི་ཚེ་ལུས་གང་གཱའི་ཀླུང་གི་བྱེ་མ་སྙེད་ཡོངས་སུ་གཏོང་ལ། ཕྱེད་ཀྱི་དུས་དང་། ཕྱི་དྲོའི་དུས་ཀྱི་ཚེ་ཡང་ལུས་གང་གཱའི་ཀླུང་གི་བྱེ་མ་སྙེད་ཡོངས་སུ་གཏོང་སྟེ། རྣམ་གྲངས་འདི་ལྟ་བུར་བསྐལ་པ་ཁྲག་ཁྲིག་བརྒྱ་སྟོང་དུ་ལུས་ཡོངས་སུ་གཏོང་བ་བས། གང་གིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་ཐོས་ནས་མི་སྤོང་ན་དེ་ཉིད་གཞི་དེ་ལས་བསོད་ནམས་ཆེས་མང་དུ་གྲངས་མེད་དཔག་ཏུ་མེད་པ་བསྐྱེད་ན། གང་གིས་ཡི་གེར་བྲིས་ནས་ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་པ་དང་། གཞན་དག་ལ་ཡང་རྒྱ་ཆེར་ཡང་དག་པར་རབ་ཏུ་སྟོན་པ་ལྟ་ཅི་སྨོས། །
            """,
            english: """
            The Tathagata speaks what is true, what is real, what does not deceive.
            And the dharma in which the Tathagata awakens is neither truly existent nor false in any ordinary sense.

            Subhuti, a bodhisattva who gives while falling into things is like a person with eyes entering darkness and seeing nothing.
            But one who gives without falling into things is like a person with eyes seeing clearly once the sun has risen.

            Those men and women who receive this teaching, hold it, read it, internalize it, and explain it widely and truly to others are known and seen by the Tathagata.
            They will generate immeasurable merit.

            If someone gave away bodies as numerous as the sands of the Ganges morning, noon, and evening for countless aeons, and another simply heard this teaching without rejecting it, the merit of the latter would be far greater.
            How much more so for one who writes it down, receives it, holds it, reads it, internalizes it, and teaches it to others.
            """
        ),

        PechaPage(
            id: "diamond-main-25",
            pageNumber: 25,
            section: .main,
            tibetan: """
            གཤེགས་པས་མཁྱེན་ཏེ། དེ་དག་དེ་བཞིན་གཤེགས་པས་གཟིགས་ཏེ། སེམས་ཅན་དེ་དག་ཐམས་ཅད་ནི་བསོད་ནམས་ཀྱི་ཕུང་པོ་དཔག་ཏུ་མེད་པ་དང་ལྡན་པར་འགྱུར་རོ། །བསོད་ནམས་ཀྱི་ཕུང་པོ་བསམ་གྱིས་མི་ཁྱབ་པ་དང་། མཚུངས་པ་མེད་པ་དང་། གཞལ་དུ་མེད་པ་དང་། ཚད་མེད་པ་དང་ལྡན་པར་འགྱུར་ཏེ། སེམས་ཅན་དེ་དག་ཐམས་ཅད་ངའི་བྱང་ཆུབ་ཕྲག་པ་ལ་ཐོགས་པར་འགྱུར་རོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དམན་པ་ལ་མོས་པ་རྣམས་ཀྱིས་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་མཉན་པར་མ་ནུས་ཏེ། བདག་ཏུ་ལྟ་བ་རྣམས་ཀྱིས་མ་ཡིན། སེམས་ཅན་དུ་ལྟ་བ་རྣམས་ཀྱིས་མ་ཡིན། སྲོག་ཏུ་ལྟ་བ་རྣམས་ཀྱིས་མ་ཡིན། གང་ཟག་ཏུ་ལྟ་བ་རྣམས་ཀྱིས་མཉན་པ་དང་། བླང་བ་དང་། གཟུང་བ་དང་། བཀླག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་མི་ནུས་ཏེ། དེ་ནི་གནས་མེད་པའི་ཕྱིར་རོ། །

            ཡང་རབ་འབྱོར་ས་ཕྱོགས་གང་ན་མདོ་སྡེ་འདི་སྟོན་པའི་ས་ཕྱོགས་དེ་ལྷ་དང་། མི་དང་། ལྷ་མ་ཡིན་དུ་བཅས་པའི་འཇིག་རྟེན་གྱིས་མཆོད་པར་འོས་པར་འགྱུར་རོ། །ས་ཕྱོགས་དེ་ཕྱག་བྱ་བར་འོས་པ་དང་། བསྐོར་བ་བྱ་བར་འོས་པར་འགྱུར་ཏེ། ས་ཕྱོགས་དེ་མཆོད་རྟེན་ལྟ་བུར་འགྱུར་རོ། །

            རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་དག་འདི་ལྟ་བུའི་མདོ་སྡེའི་ཚིག་འདི་དག་ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་པ་དེ་དག་ནི་མནར་བར་འགྱུར། ཤིན་དུ་མནར་བར་འགྱུར་རོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་སེམས་ཅན་དེ་དག་གི་ཚེ་རབས་སྔ་མའི་མི་དགེ་བའི་ལས་ངན་སོང་དུ་སྐྱེ་བར་འགྱུར་བ་གང་དག་བྱས་པ་དག་ཚེ་འདི་ཉིད་ལ་མནར་བས་ཚེ་རབས་སྔ་མའི་མི་དགེ་བའི་ལས་དེ་དག་བྱང་བར་འགྱུར་ཏེ་སངས་རྒྱས་ཀྱི་བྱང་ཆུབ་ཀྱང་ཐོབ་པར་འགྱུར་བའི་ཕྱིར་རོ། །

            རབ་འབྱོར་ངས་མངོན་པར་ཤེས་ཏེ། འདས་པའི་དུས་བསྐལ་པ་གྲངས་མེད་པའི་ཡང་ཆེས་གྲངས་མེད་པ་ན། དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་མར་མེ་མཛད་ཀྱི་ཕ་རོལ་གྱི་ཡང་ཆེས་ཕ་རོལ་ན་སངས་རྒྱས་བྱེ་བ་ཁྲག་ཁྲིག་སྟོང་ཕྲག་བརྒྱད་ཅུ་རྩ་བཞི་དག་བྱུང་བ་ངས་མཉེས་པར་བྱས་ཏེ། མཉེས་པར་བྱས་ནས་ཐུགས་མ་བྱུང་བར་བྱས་ཏེ། རབ་འབྱོར་སངས་རྒྱས་བཅོམ་ལྡན་འདས་དེ་དག་ངས་མཉེས་པར་བྱས་ནས་ཐུགས་བྱུང་བར་མ་བྱས་པ་གང་ཡིན་པ་དང་། ཕྱི་མའི་དུས་ལྔ་བརྒྱ་ཐ་མར་གྱུར་པ་ན་མདོ་སྡེ་འདི་
            """,
            english: """
            The Tathagata knows such people and sees them.
            All of them will possess a heap of merit beyond measure:
            inconceivable, incomparable, immeasurable, without limit.
            All of them will carry my awakening on their shoulders.

            Why?
            Because those attached to the lesser path cannot bear this teaching.
            Those fixed in views of self, being, life, or person cannot truly hear it, receive it, hold it, read it, or internalize it.

            And wherever this sutra is taught, that place is worthy of reverence by gods, humans, and asuras.
            It is worthy of prostration and circumambulation, like a stupa.

            Those who receive, hold, read, and internalize these words may be despised and heavily afflicted.
            Why?
            Because harmful actions from former lives that would otherwise lead to unfortunate rebirths are exhausted through that very suffering in this life, and through that purification they will reach buddhahood.

            I know this clearly, Subhuti:
            in inconceivably remote ages, even before Dipankara Buddha, I served and pleased eighty-four hundred thousand myriads of buddhas without displeasing them.
            """
        ),

        PechaPage(
            id: "diamond-main-26",
            pageNumber: 26,
            section: .main,
            tibetan: """
            ལེན་པ་དང་། འཛིན་པ་དང་། ཀློག་པ་དང་། ཀུན་ཆུབ་པར་བྱེད་པ་གང་ཡིན་པ་ལས། རབ་འབྱོར་བསོད་ནམས་ཀྱི་ཕུང་པོ་འདི་ལ་བསོད་ནམས་ཀྱི་ཕུང་པོ་སྔ་མས་བརྒྱའི་ཆར་ཡང་མི་ཕོད། སྟོང་གི་ཆ་དང་། བརྒྱ་སྟོང་གི་ཆ་དང་། གྲངས་དང་། ཆ་དང་། བགྲང་བ་དང་། དཔེ་དང་། ཟླ་དང་། རྒྱུར་ཡང་མི་བཟོད་དོ། །

            རབ་འབྱོར་གལ་ཏེ་དེའི་ཚེ་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དག་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཇི་སྙེད་རབ་ཏུ་འཛིན་པར་འགྱུར་བའི་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དེ་དག་གི་བསོད་ནམས་ཀྱི་ཕུང་པོ་ངས་བརྗོད་ན། སེམས་ཅན་རྣམས་མྱོ་མྱོ་པོར་འགྱུར་ཏེ། སེམས་འཁྲུགས་པར་འགྱུར་རོ། །

            ཡང་རབ་འབྱོར་ཆོས་ཀྱི་རྣམ་གྲངས་འདི་བསམ་གྱིས་མི་ཁྱབ་སྟེ། འདིའི་རྣམ་པར་སྨིན་པ་ཡང་བསམ་གྱིས་མི་ཁྱབ་པར་རིག་པར་བྱའོ། །
            """,
            english: """
            Compared with the merit of receiving, holding, reading, and internalizing this sutra, all the former merit would not equal even a hundredth part, nor a thousandth part, nor any fraction, number, measure, comparison, likeness, or cause.

            If I were to describe how much merit such men or women would gather, beings would become bewildered and their minds would be thrown into confusion.

            And again, Subhuti, this teaching is inconceivable, and its ripening too must be understood as inconceivable.
            """
        ),

        PechaPage(
            id: "diamond-main-27",
            pageNumber: 27,
            section: .main,
            tibetan: """
            དེ་ནས་བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་ཇི་ལྟར་གནས་པར་བགྱི། ཇི་ལྟར་བསྒྲུབ་པར་བགྱི། ཇི་ལྟར་སེམས་རབ་ཏུ་གཟུང་བར་བགྱི། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ལ་བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་འདི་སྙམ་དུ་བདག་གིས་སེམས་ཅན་ཐམས་ཅད་ཕུང་པོའི་ལྷག་མ་མེད་པའི་མྱ་ངན་ལས་འདས་པའི་དབྱིངས་སུ་ཡོངས་སུ་མྱ་ངན་ལས་འདའོ། །དེ་ལྟར་སེམས་ཅན་ཡོངས་སུ་མྱ་ངན་ལས་འདས་ཀྱང་སེམས་ཅན་གང་ཡང་ཡོངས་སུ་མྱ་ངན་ལས་འདས་པར་གྱུར་པ་མེད་དོ་སྙམ་དུ་སེམས་བསྐྱེད་པར་བྱའོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གལ་ཏེ་བྱང་ཆུབ་སེམས་དཔའ་སེམས་ཅན་དུ་འདུ་ཤེས་འཇུག་ན་དེ་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་མི་བྱ་ལ། གང་ཟག་གི་བར་དུ་འདུ་ཤེས་འཇུག་ན་དེ་ཡང་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་མི་བྱ་བའི་ཕྱིར་རོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གང་བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པ་ཞེས་བྱ་བའི་ཆོས་དེ་གང་ཡང་མེད་པའི་ཕྱིར་རོ། །
            """,
            english: """
            Then Subhuti asked:
            “Blessed One, how should one who has truly entered the bodhisattva way stand, train, and place the mind?”

            The Blessed One said:
            “One who has entered this way should think:
            ‘I will bring all beings into the realm beyond sorrow, where no trace remains.’
            And yet, even when all beings have been brought into that peace, no being at all has been brought there.

            Why?
            Because if a bodhisattva falls into the perception of being, or even of personhood, that one is not truly called a bodhisattva.
            Why?
            Because no dharma can be found that is called ‘entry into the bodhisattva vehicle.’”
            """
        ),

        PechaPage(
            id: "diamond-main-28",
            pageNumber: 28,
            section: .main,
            tibetan: """
            ཡང་ཡོད་དམ། དེ་སྐད་ཅེས་བཀའ་སྩལ་ནས། བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པས་དེ་བཞིན་གཤེགས་པ་མར་མེ་མཛད་ལས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །

            དེ་སྐད་ཅེས་གསོལ་པ་དང་། བཅོམ་ལྡན་འདས་ཀྱིས་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་ལ་འདི་སྐད་ཅེས་བཀའ་སྩལ་ཏོ། །རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། དེ་བཞིན་གཤེགས་པ་མར་མེ་མཛད་ལས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མེད་དོ། །

            རབ་འབྱོར་གལ་ཏེ་དེ་བཞིན་གཤེགས་པས་གང་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་འགའ་ཞིག་ཡོད་པར་གྱུར་ན། དེ་བཞིན་གཤེགས་པ་མར་མེ་མཛད་ཀྱིས་ང་ལ་བྲམ་ཟེའི་ཁྱེའུ་ཁྱོད་མ་འོངས་པའི་དུས་ན་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཤཱཀྱ་ཐུབ་པ་ཞེས་བྱ་བར་འགྱུར་རོ་ཞེས་ལུང་མི་སྟོན་པ་ཞིག་ན།

            རབ་འབྱོར་འདི་ལྟར་དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མེད་པས་དེའི་ཕྱིར་དེ་བཞིན་གཤེགས་པ་མར་མེ་མཛད་ཀྱིས་ང་ལ་བྲམ་ཟེའི་ཁྱེའུ་ཁྱོད་མ་འོངས་པའི་དུས་ན་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཤཱཀྱ་ཐུབ་པ་ཞེས་བྱ་བར་འགྱུར་རོ་ཞེས་ལུང་བསྟན་ཏོ། །
            """,
            english: """
            “Is there any such dharma at all?”

            Subhuti replied:
            “Blessed One, there is no dharma at all by which the Tathagata, from Dipankara Buddha, attained unsurpassed perfect awakening.”

            The Blessed One said:
            “Exactly so, Subhuti. Exactly so.
            There is no dharma at all by which the Tathagata attained unsurpassed perfect awakening from Dipankara Buddha.

            If there had been such a dharma, Dipankara Buddha would not have foretold of me:
            ‘In a future time you will become the Tathagata, Arhat, Fully Awakened Buddha called Shakyamuni.’

            Precisely because there is no such dharma at all, that prophecy was given.”
            """
        ),

        PechaPage(
            id: "diamond-main-29",
            pageNumber: 29,
            section: .main,
            tibetan: """
            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པ་ཞེས་བྱ་བ་ནི་ཡང་དག་པ་དེ་བཞིན་ཉིད་ཀྱི་ཚིག་བླ་དགས་ཡིན་པའི་ཕྱིར་རོ། །རབ་འབྱོར་གང་ལ་ལ་ཞིག་འདི་སྐད་དུ། དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱིས་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་སོ་ཞེས་ཟེར་ན་དེ་ལོག་པར་སྨྲ་བ་ཡིན་ནོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མེད་པའི་ཕྱིར་རོ། །རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་ཆོས་གང་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པ་དེ་ལ་བདེན་པ་
            """,
            english: """
            Why?
            Because the word `Tathagata` is just another name for suchness itself.

            If anyone were to say,
            ‘The Tathagata, Arhat, Fully Awakened Buddha has attained unsurpassed perfect awakening,’
            that person would be speaking wrongly.

            Why?
            Because there is no dharma at all by which the Tathagata attained unsurpassed perfect awakening.
            And the dharma in which the Tathagata awakens is not something that can be fixed as an object of grasping.”
            """
        ),

        PechaPage(
            id: "diamond-main-30",
            pageNumber: 30,
            section: .main,
            tibetan: """
            ཡང་མེད་བརྫུན་པ་ཡང་མེད་དེ། དེ་བས་ན་དེ་བཞིན་གཤེགས་པས་ཆོས་ཐམས་ཅད་སངས་རྒྱས་ཀྱི་ཆོས་སོ་ཞེས་གསུངས་སོ། །རབ་འབྱོར་ཆོས་ཐམས་ཅད་ཅེས་བྱ་བ་ནི་དེ་དག་ཐམས་ཅད་ཆོས་མེད་པ་ཡིན་ཏེ། དེ་བས་ན་ཆོས་ཐམས་ཅད་སངས་རྒྱས་ཀྱི་ཆོས་ཞེས་བྱ་སྟེ།

            རབ་འབྱོར་འདི་ལྟ་སྟེ། དཔེར་ན་མི་ཞིག་ལུས་དང་ལྡན་ཞིང་ལུས་ཆེན་པོར་གྱུར་པ་བཞིན་ནོ། །ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པས་མི་ལུས་དང་ལྡན་ཞིང་ལུས་ཆེན་པོ་ཞེས་གང་གསུངས་པ་དེ། དེ་བཞིན་གཤེགས་པས་ལུས་མ་མཆིས་པར་གསུངས་ཏེ། དེས་ན་ལུས་དང་ལྡན་ཞིང་ལུས་ཆེན་པོ་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་བཞིན་ཏེ། བྱང་ཆུབ་སེམས་དཔའ་གང་འདི་སྐད་དུ་བདག་གིས་སེམས་ཅན་རྣམས་ཡོངས་སུ་མྱ་ངན་ལས་འདའོ་ཞེས་ཟེར་ན་དེ་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་མི་བྱའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་གང་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་བྱ་བའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་མཆིས་སོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་བས་ན་དེ་བཞིན་གཤེགས་པས་ཆོས་ཐམས་ཅད་ནི་སེམས་ཅན་མེད་པ། སྲོག་མེད་པ། གང་ཟག་མེད་པ་ཞེས་གསུངས་སོ། །རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་གང་ཞིག་འདི་སྐད་དུ། བདག་གིས་ཞིང་བཀོད་པ་རྣམས་བསྒྲུབ་བོ་ཞེས་ཟེར་ན་དེ་ཡང་དེ་བཞིན་དུ་བརྗོད་པར་བྱའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་ཞིང་བཀོད་པ་རྣམས་ཞིང་བཀོད་པ་རྣམས་ཞེས་བྱ་བ་ནི་དེ་དག་བཀོད་པ་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་ཕྱིར་ཏེ། དེ་བས་ན་ཞིང་བཀོད་པ་རྣམས་ཞེས་བྱའོ། །

            རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་གང་ཞིག་ཆོས་རྣམས་ནི་བདག་མེད་པའོ། །ཆོས་རྣམས་ནི་བདག་མེད་པའོ་ཞེས་མོས་པ་དེ་ནི་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱིས་བྱང་ཆུབ་སེམས་དཔའ་བྱང་ཆུབ་སེམས་དཔའ་ཞེས་བརྗོད་དོ། །
            """,
            english: """
            There is neither truth nor falsehood there in any ordinary sense.
            That is why the Tathagata says, “All dharmas are buddhadharmas.”
            Yet what are called “all dharmas” are precisely no-dharmas.

            Suppose, Subhuti, a person had a great body.
            Subhuti said:
            “What the Tathagata calls a great body is spoken of that way only because no fixed body can be found there.”

            The Blessed One said:
            “Just so, if a bodhisattva says, ‘I will bring beings into nirvana,’ that one is not truly called a bodhisattva.
            Why?
            Because no dharma can be found that is called ‘bodhisattva.’

            Therefore the Tathagata says that all dharmas are without being, without life, without person.
            And if a bodhisattva says, ‘I will establish buddha-fields,’ that too is only spoken conventionally, because no fixed field can be found there.

            One who truly trusts that dharmas are selfless is the one the Tathagata calls a bodhisattva.” 
            """
        ),

        PechaPage(
            id: "diamond-main-31",
            pageNumber: 31,
            section: .main,
            tibetan: """
            བཞིན་གཤེགས་པ་ལ་ཤའི་སྤྱན་མངའོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་ལ་ལྷའི་སྤྱན་མངའ་འམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། དེ་བཞིན་གཤེགས་པ་ལ་ལྷའི་སྤྱན་མངའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་ལ་ཤེས་རབ་ཀྱི་སྤྱན་མངའ་འམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། དེ་བཞིན་གཤེགས་པ་ལ་ཤེས་རབ་ཀྱི་སྤྱན་མངའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་ལ་ཆོས་ཀྱི་སྤྱན་མངའ་འམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། དེ་བཞིན་གཤེགས་པ་ལ་ཆོས་ཀྱི་སྤྱན་མངའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་ལ་སངས་རྒྱས་ཀྱི་སྤྱན་མངའ་འམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། དེ་བཞིན་གཤེགས་པ་ལ་སངས་རྒྱས་ཀྱི་སྤྱན་མངའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། གང་གཱའི་ཀླུང་གི་བྱེ་མ་ཇི་སྙེད་པ་གང་གཱའི་ཀླུང་ཡང་དེ་སྙེད་དུ་གྱུར་ལ། དེ་དག་གི་བྱེ་མ་སྙེད་པ་དེ་སྙེད་ཀྱི་འཇིག་རྟེན་གྱི་ཁམས་སུ་གྱུར་ན་འཇིག་རྟེན་གྱི་ཁམས་དེ་མང་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། འཇིག་རྟེན་གྱི་ཁམས་དེ་དག་མང་བ་ལགས་སོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འཇིག་རྟེན་གྱི་ཁམས་དེ་དག་ན་སེམས་ཅན་ཇི་སྙེད་ཡོད་པ་དེ་དག་གི་བསམ་པ་ཐ་དད་པའི་སེམས་ཀྱི་རྒྱུད་ངས་རབ་ཏུ་ཤེས་སོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་སེམས་ཀྱི་རྒྱུད་སེམས་ཀྱི་རྒྱུད་ཅེས་བྱ་བ་ནི་དེ་རྒྱུད་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་སེམས་ཀྱི་རྒྱུད་ཅེས་བྱའོ། །
            """,
            english: """
            The Blessed One said:
            “What do you think, Subhuti? Does the Tathagata possess the fleshly eye?”
            “Yes.”
            “The heavenly eye?”
            “Yes.”
            “The wisdom eye?”
            “Yes.”
            “The Dharma eye?”
            “Yes.”
            “The Buddha eye?”
            “Yes.”

            “What do you think, Subhuti? If there were as many Ganges rivers as grains of sand in the Ganges, and as many world-systems as there are sands in all those rivers, would those world-systems be many?”
            Subhuti said, “Very many.”

            The Blessed One said:
            “In all those world-systems, whatever differing streams of thought there are in beings, I know them fully.
            Why?
            Because what is called a stream of mind is spoken of that way only because no fixed mind-stream can be found there.”
            """
        ),

        PechaPage(
            id: "diamond-main-32",
            pageNumber: 32,
            section: .main,
            tibetan: """
            དམིགས་སུ་མེད་པའི་ཕྱིར་རོ། །རབ་འབྱོར་དེ་ཇི་སྙམ་དུ་སེམས། གང་གིས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་འདི་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་ཡོངས་སུ་གང་བར་བྱས་ཏེ་སྦྱིན་པ་བྱིན་ན། རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དེ་གཞི་དེ་ལས་བསོད་ནམས་མང་དུ་སྐྱེད་དམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་མང་ལགས་སོ། །བདེ་བར་གཤེགས་པ་མང་ལགས་སོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་དེ་གཞི་དེ་ལས་བསོད་ནམས་ཀྱི་ཕུང་པོ་མང་པོ་སྐྱེད་དོ། །རབ་འབྱོར་གལ་ཏེ་བསོད་ནམས་ཀྱི་ཕུང་པོར་གྱུར་ན། བསོད་ནམས་ཀྱི་ཕུང་པོ་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཞེས་དེ་བཞིན་གཤེགས་པ་མི་གསུང་ངོ་། །

            རབ་འབྱོར་དེ་ཇི་སྙམ་དུ་སེམས། གཟུགས་ཀྱི་སྐུ་ཡོངས་སུ་གྲུབ་པས་དེ་བཞིན་གཤེགས་པར་བལྟའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་ཏེ། གཟུགས་ཀྱི་སྐུ་ཡོངས་སུ་གྲུབ་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་གཟུགས་ཀྱི་སྐུ་ཡོངས་སུ་གྲུབ་པས་གཟུགས་ཀྱི་སྐུ་ཡོངས་སུ་རྫོགས་པ་ཞེས་བགྱི་བ་ནི་དེ་ཡོངས་སུ་གྲུབ་པ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་གཟུགས་ཀྱི་སྐུ་ཡོངས་སུ་གྲུབ་པ་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་བལྟའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་ཏེ། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། དེ་བཞིན་གཤེགས་པས་མཚན་ཕུན་སུམ་ཚོགས་པར་གསུངས་པ་དེ་མཚན་ཕུན་སུམ་ཚོགས་པ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་མཚན་ཕུན་སུམ་ཚོགས་པ་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་འདི་སྙམ་དུ་ངས་ཆོས་བསྟན་ཏོ་ཞེས་དགོངས་སོ་སྙམ་ན། རབ་འབྱོར་དེ་ལྟར་མི་བལྟ་སྟེ། དེ་བཞིན་གཤེགས་པས་གང་བསྟན་པའི་ཆོས་དེ་གང་ཡང་མེད་དོ། །
            """,
            english: """
            Because no mind, whether past, future, or present, can be found as an object.

            What do you think, Subhuti? If someone filled this entire three-thousandfold world-system with the seven precious things and gave them away, would much merit come from that?”
            Subhuti said, “Very much.”

            The Blessed One said:
            “Exactly so. Yet if it were truly a fixed heap of merit, the Tathagata would not call it a heap of merit.

            What do you think? Can the Tathagata be seen by means of a fully perfected form-body?”
            Subhuti said, “No.
            Why?
            Because what is called a perfected form-body is spoken of that way only because no fixed body can be found there.”

            “And can the Tathagata be seen by the perfection of marks?”
            “No.
            Because what is called the perfection of marks is spoken of that way only because no fixed marks can be found there.”

            “And if anyone thinks, ‘The Tathagata has taught a Dharma,’ do not see it that way.
            There is no fixed dharma that the Tathagata has taught.”
            """
        ),

        PechaPage(
            id: "diamond-main-33",
            pageNumber: 33,
            section: .main,
            tibetan: """
            འབྱོར་སུ་ཞིག་འདི་སྐད་དུ་དེ་བཞིན་གཤེགས་པས་ཆོས་བསྟན་ཏོ་ཞེས་ཟེར་ན། རབ་འབྱོར་དེ་ནི་མེད་པ་དང་ལོག་པར་ཟིན་པས་ང་ལ་སྐུར་བར་འགྱུར་རོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་ཆོས་བསྟན་པ་ཞེས་བྱ་བ་དམིགས་པར་འགྱུར་བའི་ཆོས་བསྟན་པ་ཆོས་བསྟན་པ་ཞེས་བྱ་བ་དེ་གང་ཡང་མེད་པའི་ཕྱིར་རོ། །

            དེ་ནས་བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་མ་འོངས་པའི་དུས་ན་སེམས་ཅན་གང་དག་འདི་ལྟ་བུའི་ཆོས་བཤད་པ་ཐོས་ནས་མངོན་པར་ཡིད་ཆེས་པར་འགྱུར་བ་མཆིས་སམ། བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དག་ནི་སེམས་ཅན་ཡང་མ་ཡིན་སེམས་ཅན་མེད་པ་ཡང་མ་ཡིན་ནོ། །

            དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་སེམས་ཅན་རྣམས་ཞེས་བྱ་བ་ནི་དེ་བཞིན་གཤེགས་པས་དེ་དག་སེམས་ཅན་མེད་པར་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་སེམས་ཅན་རྣམས་ཞེས་བྱའོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། དེ་ཆོས་ཅུང་ཟད་ཀྱང་མེད་ཅིང་མི་དམིགས་ཏེ་དེས་ན་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཅེས་བྱའོ། །

            ཡང་རབ་འབྱོར་ཆོས་དེ་ནི་མཉམ་པ་སྟེ། དེ་ལ་མི་མཉམ་པ་གང་ཡང་མེད་པས་དེས་ན་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཅེས་བྱའོ། །བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ནི་བདག་མེད་པ་དང་། སེམས་ཅན་མེད་པ་དང་། སྲོག་མེད་པ་དང་། གང་ཟག་མེད་པར་མཉམ་སྟེ། དགེ་བའི་ཆོས་ཐམས་ཅད་ཀྱིས་མངོན་པར་རྫོགས་པར་འཚང་རྒྱའོ། །རབ་འབྱོར་དགེ་བའི་ཆོས་རྣམས་དགེ་བའི་ཆོས་རྣམས་ཞེས་བྱ་བ་ནི་དེ་དག་དེ་བཞིན་གཤེགས་པས་ཆོས་མེད་པ་ཉིད་དུ་གསུངས་ཏེ། དེས་ན་དགེ་བའི་ཆོས་རྣམས་ཞེས་བྱའོ། །
            """,
            english: """
            If anyone says, ‘The Tathagata has taught a Dharma,’ that person misunderstands and clings wrongly, thereby slandering me.
            Why?
            Because what is called ‘teaching Dharma’ cannot be grasped as any fixed thing.

            Then Subhuti asked:
            “In future times, will there be beings who, hearing such a teaching, will truly trust it?”

            The Blessed One said:
            “Those are not truly beings, nor are they no-beings.
            Why?
            Because what are called beings are spoken of that way only because no fixed beings can be found there.

            And what do you think? Is there any dharma at all by which the Tathagata attained unsurpassed perfect awakening?”
            Subhuti said, “No.”

            The Blessed One said:
            “Exactly so.
            There is not even the slightest dharma there, and it cannot be apprehended.
            That is why it is called unsurpassed perfect awakening.

            This dharma is equal; there is nothing unequal in it.
            Because it is free from self, being, life, and person, it is fully awakened through all wholesome dharmas.
            Yet what are called wholesome dharmas are also spoken of that way only because no fixed dharmas can be found there.”
            """
        ),

        PechaPage(
            id: "diamond-main-34",
            pageNumber: 34,
            section: .main,
            tibetan: """
            ཡོད་པ་དེ་ཙམ་གྱི་རིན་པོ་ཆེ་སྣ་བདུན་གྱི་ཕུང་པོ་མངོན་པར་བསྡུས་ཏེ་སྦྱིན་པ་བྱིན་པ་བས་གང་གིས་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་བཟུང་ནས་གཞན་དག་ལ་ཡང་བསྟན་ན། རབ་འབྱོར་བསོད་ནམས་ཀྱི་ཕུང་པོ་འདི་ལ་བསོད་ནམས་ཀྱི་ཕུང་པོ་སྔ་མ་དེས་བརྒྱའི་ཆར་ཡང་མི་ཕོད་པ་ནས་རྒྱུའི་བར་དུ་ཡང་མི་བཟོད་དོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པ་འདི་སྙམ་དུ་ངས་སེམས་ཅན་རྣམས་བཀྲོལ་ལོ་ཞེས་དགོངས་སོ་སྙམ་ན། རབ་འབྱོར་དེ་དེ་ལྟར་མི་བལྟའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པས་གང་བཀྲོལ་བའི་སེམས་ཅན་དེ་དག་གང་ཡང་མེད་པའི་ཕྱིར་རོ། །

            རབ་འབྱོར་གལ་ཏེ་དེ་བཞིན་གཤེགས་པས་སེམས་ཅན་གང་ལ་ལ་ཞིག་བཀྲོལ་བར་གྱུར་ན་དེ་ཉིད་དེ་བཞིན་གཤེགས་པའི་བདག་ཏུ་འཛིན་པར་འགྱུར། སེམས་ཅན་དུ་འཛིན་པ་དང་། སྲོག་ཏུ་འཛིན་པ་དང་། གང་ཟག་ཏུ་འཛིན་པར་འགྱུར་རོ། །

            རབ་འབྱོར་བ་དག་ཏུ་འཛིན་ཅེས་བྱ་བ་ནི་དེ་འཛིན་པ་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ན་དེ་ཡང་བྱིས་པ་སོ་སོའི་སྐྱེ་བོ་རྣམས་ཀྱིས་བཟུང་ངོ་། །རབ་འབྱོར་བྱིས་པ་སོ་སོའི་སྐྱེ་བོ་རྣམས་ཞེས་བྱ་བ་ནི་དེ་དག་སྐྱེ་བོ་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ། དེས་ན་བྱིས་པ་སོ་སོའི་སྐྱེ་བོ་རྣམས་ཞེས་བྱའོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས་མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་བལྟའམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་ཏེ། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དེ་བཞིན་ཏེ། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །རབ་འབྱོར་གལ་ཏེ་མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་བལྟ་བར་གྱུར་ན་འཁོར་ལོས་སྒྱུར་བའི་རྒྱལ་པོ་ཡང་དེ་བཞིན་གཤེགས་པར་འགྱུར་ཏེ་དེ་བས་ན་མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །

            དེ་ནས་བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་ཀྱིས་གསུངས་པའི་དོན་བདག་གིས་འཚལ་བ་ལྟར་ན་མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པར་མི་བལྟའོ། །དེ་ནས་བཅོམ་ལྡན་འདས་ཀྱིས་དེའི་ཚེ་ཚིགས་སུ་བཅད་པ་འདི་དག་བཀའ་སྩལ་ཏོ། །
            """,
            english: """
            Even if someone offered heaps of the seven precious things equal to such a measure, and another took even four lines from this Perfection of Wisdom and taught them to others, the former merit would not approach the latter even by a hundredth part, nor by any fraction or comparison at all.

            What do you think, Subhuti? Does the Tathagata think, ‘I have liberated beings’?
            Do not see it that way.
            Why?
            Because there are no beings at all whom the Tathagata has liberated.

            If the Tathagata had liberated even a single being, that would already imply grasping at self, being, life, or person.
            What the Tathagata calls grasping is spoken of that way only because there is in truth no such grasping, though ordinary beings seize upon it.

            What are called ordinary beings are spoken of that way only because no fixed ordinary beings can be found there.

            And what do you think? Can the Tathagata be seen by the fullness of marks?
            Subhuti said, “No.”
            The Blessed One said:
            “Exactly so.
            If the Tathagata could be seen by the fullness of marks, then even a wheel-turning king would count as a Tathagata.
            Therefore the Tathagata is not seen by the fullness of marks.”

            Subhuti then said:
            “As I understand the Blessed One’s meaning, the Tathagata is not seen through the fullness of marks.”
            """
        ),

        PechaPage(
            id: "diamond-main-35",
            pageNumber: 35,
            section: .main,
            tibetan: """
            ཞུགས་པ་སྟེ། །སྐྱེ་བོ་དེ་དག་ང་མི་མཐོང་། །སངས་རྒྱས་རྣམས་ནི་ཆོས་ཉིད་བལྟ། །འདྲེན་པ་རྣམས་ནི་ཆོས་ཀྱི་སྐུ། །ཆོས་ཉིད་རིག་པར་བྱ་མིན་པས། །དེ་ནི་རྣམ་པར་ཤེས་མི་ནུས། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་སོ་སྙམ་དུ་འཛིན་ན། རབ་འབྱོར་ཁྱོད་ཀྱིས་དེ་ལྟར་མི་བལྟ་སྟེ། རབ་འབྱོར་མཚན་ཕུན་སུམ་ཚོགས་པས་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཀྱིས་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པ་མེད་དོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པ་རྣམས་ཀྱིས་ཆོས་ལ་ལ་ཞིག་རྣམ་པར་བཤིག་གམ། ཆད་པར་བཏགས་པ་སྙམ་དུ་འཛིན་ན། རབ་འབྱོར་དེ་ལྟར་མི་བལྟ་སྟེ། བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པ་རྣམས་ཀྱིས་ཆོས་གང་ལ་ཡང་རྣམ་པར་བཤིག་པའམ། ཆད་པར་བཏགས་པ་མེད་དོ། །

            ཡང་རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་གིས་འཇིག་རྟེན་གྱི་ཁམས་གང་གཱའི་ཀླུང་གི་བྱེ་མ་སྙེད་དག་རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ་སྦྱིན་པ་བྱིན་པ་བས། བྱང་ཆུབ་སེམས་དཔའ་གང་ཞིག་ཆོས་རྣམས་བདག་མེད་ཅིང་སྐྱེ་བ་མེད་པ་ལ་བཟོད་པ་ཐོབ་ན་དེ་ཉིད་གཞི་དེ་ལས་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཆེས་མང་དུ་སྐྱེད་དོ། །

            ཡང་རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔས་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཡོངས་སུ་གཟུང་བར་མི་བྱའོ། །
            """,
            english: """
            Those who seek me in form,
            or know me by sound,
            are turned toward the wrong path:
            they do not see me.

            The Buddhas are to be seen in dharma itself.
            The guides are dharma-body.
            Yet dharma itself cannot be grasped as an object,
            and so cannot be known in the ordinary way.

            Subhuti, do not think that the Tathagata, Arhat, Fully Awakened Buddha is known through the fullness of marks.
            No such awakening is attained through marks.

            And do not think that those who have entered the bodhisattva vehicle destroy or annihilate any dharma.
            They do not.

            If someone filled world-systems as numerous as the sands of the Ganges with the seven precious things and gave them away, and another bodhisattva attained patience with the selflessness and non-arising of dharmas, the latter would generate far greater merit.

            Yet, Subhuti, the bodhisattva should not cling to any heap of merit.
            """
        ),

        PechaPage(
            id: "diamond-main-36",
            pageNumber: 36,
            section: .main,
            tibetan: """
            ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་བྱང་ཆུབ་སེམས་དཔས་བསོད་ནམས་ཀྱི་ཕུང་པོ་ཡོངས་སུ་གཟུང་བར་མི་བགྱི་ལགས་སམ། བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་ཡོངས་སུ་གཟུང་མོད་ཀྱིས་ལོག་པར་མི་གཟུང་སྟེ། དེས་ན་ཡོངས་སུ་གཟུང་བ་ཞེས་བྱའོ། །

            རབ་འབྱོར་གང་ལ་ལ་ཞིག་འདི་སྐད་དུ། དེ་བཞིན་གཤེགས་པ་བཞུད་དམ། བྱོན་ཏམ། བཞེངས་སམ། བཞུགས་སམ། མནལ་བ་མཛད་དོ་ཞེས་དེ་སྐད་ཟེར་ན། དེས་ན་ངས་བཤད་པའི་དོན་མི་ཤེས་སོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་དེ་བཞིན་གཤེགས་པ་ཞེས་བྱ་བ་ནི་གར་ཡང་མ་བཞུད། གང་ནས་ཀྱང་མ་བྱོན་པའི་ཕྱིར་ཏེ། དེས་ན་དེ་བཞིན་གཤེགས་པ་དགྲ་བཅོམ་པ་ཡང་དག་པར་རྫོགས་པའི་སངས་རྒྱས་ཞེས་བྱའོ། །
            """,
            english: """
            Subhuti asked, “Blessed One, should the bodhisattva then not fully receive merit?”

            The Blessed One said:
            “Receive it fully, yes, but do not seize it wrongly.
            That is what is meant by fully receiving it.”

            And if anyone says,
            ‘The Tathagata goes, comes, stands, sits, or lies down,’
            that person does not understand what I have said.

            Why?
            Because the Tathagata does not go anywhere and does not come from anywhere.
            That is why the one thus called is the Tathagata, Arhat, Fully Awakened Buddha.
            """
        ),

        PechaPage(
            id: "diamond-main-37",
            pageNumber: 37,
            section: .main,
            tibetan: """
            འབྱོར་སུ་ཞིག་འདི་སྐད་དུ་དེ་བཞིན་གཤེགས་པས་ཆོས་བསྟན་ཏོ་ཞེས་ཟེར་ན། རབ་འབྱོར་དེ་ནི་མེད་པ་དང་ལོག་པར་ཟིན་པས་ང་ལ་སྐུར་བར་འགྱུར་རོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་ཆོས་བསྟན་པ་ཞེས་བྱ་བ་དམིགས་པར་འགྱུར་བའི་ཆོས་བསྟན་པ་ཆོས་བསྟན་པ་ཞེས་བྱ་བ་དེ་གང་ཡང་མེད་པའི་ཕྱིར་རོ། །

            དེ་ནས་བཅོམ་ལྡན་འདས་ལ་ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་འདི་སྐད་ཅེས་གསོལ་ཏོ། །བཅོམ་ལྡན་འདས་མ་འོངས་པའི་དུས་ན་སེམས་ཅན་གང་དག་འདི་ལྟ་བུའི་ཆོས་བཤད་པ་ཐོས་ནས་མངོན་པར་ཡིད་ཆེས་པར་འགྱུར་བ་མཆིས་སམ། བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དག་ནི་སེམས་ཅན་ཡང་མ་ཡིན་སེམས་ཅན་མེད་པ་ཡང་མ་ཡིན་ནོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་སེམས་ཅན་རྣམས་ཞེས་བྱ་བ་ནི་དེ་བཞིན་གཤེགས་པས་དེ་དག་སེམས་ཅན་མེད་པར་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་སེམས་ཅན་རྣམས་ཞེས་བྱའོ། །

            རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་ཡོད་དམ། ཚེ་དང་ལྡན་པ་རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་བཞིན་གཤེགས་པས་གང་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་མངོན་པར་རྫོགས་པར་སངས་རྒྱས་པའི་ཆོས་དེ་གང་ཡང་མ་མཆིས་སོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་དེ་དེ་བཞིན་ནོ། །དེ་དེ་བཞིན་ཏེ། དེ་ཆོས་ཅུང་ཟད་ཀྱང་མེད་ཅིང་མི་དམིགས་ཏེ་དེས་ན་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཅེས་བྱའོ། །

            ཡང་རབ་འབྱོར་ཆོས་དེ་ནི་མཉམ་པ་སྟེ། དེ་ལ་མི་མཉམ་པ་གང་ཡང་མེད་པས་དེས་ན་བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ཅེས་བྱའོ། །བླ་ན་མེད་པ་ཡང་དག་པར་རྫོགས་པའི་བྱང་ཆུབ་ནི་བདག་མེད་པ་དང་། སེམས་ཅན་མེད་པ་དང་། སྲོག་མེད་པ་དང་། གང་ཟག་མེད་པར་མཉམ་སྟེ། དགེ་བའི་ཆོས་ཐམས་ཅད་ཀྱིས་མངོན་པར་རྫོགས་པར་འཚང་རྒྱའོ། །རབ་འབྱོར་དགེ་བའི་ཆོས་རྣམས་དགེ་བའི་ཆོས་རྣམས་ཞེས་བྱ་བ་ནི་དེ་དག་དེ་བཞིན་གཤེགས་པས་ཆོས་མེད་པ་ཉིད་དུ་གསུངས་ཏེ། དེས་ན་དགེ་བའི་ཆོས་རྣམས་ཞེས་བྱའོ། །

            ཡང་རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་ལ་ལ་ཞིག་གིས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་ན་རིའི་རྒྱལ་པོ་རི་རབ་དག་ཇི་སྙེད་ཡོད་པ་དེ་ཙམ་གྱི་རིན་པོ་ཆེ་སྣ་བདུན་གྱི་ཕུང་པོ་མངོན་པར་བསྡུས་ཏེ་སྦྱིན་པ་བྱིན་པ་བས། གང་གིས་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་བཟུང་ནས་གཞན་དག་ལ་ཡང་བསྟན་ན། རབ་འབྱོར་བསོད་ནམས་ཀྱི་ཕུང་པོ་འདི་ལ་བསོད་ནམས་ཀྱི་ཕུང་པོ་སྔ་མ་དེས་བརྒྱའི་ཆར་ཡང་མི་ཕོད་པ་ནས་རྒྱུའི་བར་དུ་ཡང་མི་བཟོད་དོ། །
            """,
            english: """
            If someone says, “The Tathagata taught a Dharma,” that person has seized wrongly and speaks against me.
            Why?
            Because no graspable thing can be found that would count as a Dharma taught.

            Then Subhuti asked:
            “In the future, will there be beings who hear such a teaching and truly trust it?”
            The Blessed One said:
            “They are not beings, and they are not non-beings either.
            What are called beings are spoken of that way only because no fixed beings can be found.”

            And what do you think, Subhuti?
            Is there any Dharma at all that the Tathagata realized as unsurpassed, complete awakening?”
            Subhuti said, “No.”
            The Blessed One said:
            “Exactly so.
            Not even the slightest Dharma can be found or pointed to there.
            That is why it is called unsurpassed, complete awakening.

            That Dharma is equal.
            In it there is no inequality at all.
            That is why it is called unsurpassed, complete awakening.
            It is equal in the absence of self, being, life, and person.
            Through all wholesome dharmas awakening is fully realized.
            Yet what are called wholesome dharmas are spoken of that way only because they are empty of any fixed dharma.”

            And if someone gathered heaps of the seven precious things as vast as all the great Mount Merus in a thousandfold world-system and gave them away, while another held even a four-line verse from this Perfection of Wisdom and taught it to others, the latter merit would far exceed the former by measures beyond counting.
            """
        ),

        PechaPage(
            id: "diamond-main-38",
            pageNumber: 38,
            section: .main,
            tibetan: """
            ཡང་རབ་འབྱོར་རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་གིས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་ན་སའི་རྡུལ་རྣམས་ཇི་སྙེད་ཡོད་པ་དེ་དག་འདི་ལྟ་སྟེ་དཔེར་ན་རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་བཞིན་དུ་ཕྱེ་མར་བྱས་ན། རབ་འབྱོར་འདི་ཇི་སྙམ་དུ་སེམས། རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་དེ་མང་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་དེ་ལྟ་ལགས་ཏེ། རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་དེ་མང་བ་ལགས་སོ། །

            དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་གལ་ཏེ་ཚོགས་ཤིག་མཆིས་པར་གྱུར་ན། བཅོམ་ལྡན་འདས་ཀྱིས་རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་ཞེས་བཀའ་མི་སྩལ་བའི་སླད་དུའོ། །དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་ཀྱིས་རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་ཞེས་གང་གསུངས་པ་དེ་ཚོགས་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་རྡུལ་ཕྲ་རབ་ཀྱི་ཚོགས་ཞེས་བགྱིའོ། །དེ་བཞིན་གཤེགས་པས་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་ཞེས་གང་གསུངས་པ་དེ་ཁམས་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ། དེས་ན་སྟོང་གསུམ་གྱི་སྟོང་ཆེན་པོའི་འཇིག་རྟེན་གྱི་ཁམས་ཞེས་བགྱིའོ། །

            དེ་ཅིའི་སླད་དུ་ཞེ་ན། བཅོམ་ལྡན་འདས་གལ་ཏེ་ཁམས་ཤིག་མཆིས་པར་གྱུར་ན། དེ་ཉིད་རིལ་པོར་འཛིན་པར་འགྱུར་བའི་སླད་དུའོ། །དེ་བཞིན་གཤེགས་པས་རིལ་པོར་འཛིན་པར་གང་གསུངས་པ་དེ་འཛིན་པ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་ཏེ། དེས་ན་རིལ་པོར་འཛིན་པ་ཞེས་བགྱིའོ། །བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་རིལ་པོར་འཛིན་པ་ཉིད་ནི་ཐ་སྙད་དེ། ཆོས་དེ་ནི་བརྗོད་དུ་མེད་པ་ཡིན་ན། དེ་ཡང་བྱིས་པ་སོ་སོའི་སྐྱེ་བོ་རྣམས་ཀྱིས་བཟུང་ངོ་། །

            རབ་འབྱོར་གང་ལ་ལ་ཞིག་འདི་སྐད་དུ། དེ་བཞིན་གཤེགས་པས་བདག་ཏུ་ལྟ་བར་གསུངས་ཏེ། དེ་བཞིན་གཤེགས་པས་སེམས་ཅན་དུ་ལྟ་བ་དང་། སྲོག་ཏུ་ལྟ་བ་དང་། གང་ཟག་ཏུ་ལྟ་བར་གསུངས་སོ་ཞེས་ཟེར་ན། རབ་འབྱོར་དེ་ཡང་དག་པར་སྨྲ་བས་སྨྲ་བ་ཡིན་ནམ། རབ་འབྱོར་གྱིས་གསོལ་པ། བཅོམ་ལྡན་འདས་དེ་ནི་མ་ལགས་སོ། །བདེ་བར་གཤེགས་པ་དེ་ནི་མ་ལགས་སོ། །
            """,
            english: """
            And again, Subhuti, suppose someone were to take all the dust in a thousandfold great world-system and grind it down into the finest motes. Would that heap of fine particles be vast?
            Subhuti said, “Yes, Blessed One, it would be vast.”

            The Blessed One said:
            “If it were truly a fixed heap, the Tathagata would not speak of it as a heap of fine particles.
            What the Tathagata calls a heap of fine particles is spoken of that way only because no fixed heap can be found there.
            And what the Tathagata calls a thousandfold great world-system is likewise spoken of that way only because no fixed world-system can be found.

            If such a system truly existed as a solid whole, it would become an object of totalizing grasp.
            Yet what the Tathagata calls grasping a whole is itself not findable.
            It is only a conventional designation, though ordinary beings take hold of it.”

            And if someone were to say,
            “The Tathagata teaches views of self, being, life, and person,”
            would that be correct?
            Subhuti said, “No, Blessed One. No, Sugata.”
            """
        ),

        PechaPage(
            id: "diamond-main-39",
            pageNumber: 39,
            section: .main,
            tibetan: """
            དེ་བཞིན་གཤེགས་པས་བདག་ཏུ་ལྟ་བར་གང་གསུངས་པ་དེ་ལྟ་བ་མ་མཆིས་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་སླད་དུ་སྟེ། དེས་ན་བདག་ཏུ་ལྟ་བ་ཞེས་བགྱིའོ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་བཀའ་སྩལ་པ། རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའི་ཐེག་པ་ལ་ཡང་དག་པར་ཞུགས་པས་འདི་ལྟར་ཆོས་ཐམས་ཅད་ཤེས་པར་བྱ་བལྟ་བར་བྱ་མོས་པར་བྱ་སྟེ། ཅི་ནས་ཆོས་སུ་འདུ་ཤེས་པ་ལ་ཡང་མི་གནས་པ་དེ་ལྟར་མོས་པར་བྱའོ། །དེ་ཅིའི་ཕྱིར་ཞེ་ན། རབ་འབྱོར་ཆོས་སུ་འདུ་ཤེས་ཆོས་སུ་འདུ་ཤེས་ཞེས་བྱ་བ་ནི་འདུ་ཤེས་མེད་པར་དེ་བཞིན་གཤེགས་པས་གསུངས་པའི་ཕྱིར་ཏེ། དེས་ན་ཆོས་སུ་འདུ་ཤེས་ཞེས་བྱའོ། །

            ཡང་རབ་འབྱོར་བྱང་ཆུབ་སེམས་དཔའ་སེམས་དཔའ་ཆེན་པོ་གང་གིས་འཇིག་རྟེན་གྱི་ཁམས་དཔག་ཏུ་མེད་ཅིང་གྲངས་མེད་པ་དག། རིན་པོ་ཆེ་སྣ་བདུན་གྱིས་རབ་ཏུ་གང་བར་བྱས་ཏེ་སྦྱིན་པ་བྱིན་པ་བས། རིགས་ཀྱི་བུའམ། རིགས་ཀྱི་བུ་མོ་གང་གིས་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་འདི་ལས་ཐ་ན་ཚིག་བཞི་པའི་ཚིགས་སུ་བཅད་པ་ཙམ་བླངས་ནས། འཛིན་ཏམ། ཀློག་གམ། ཀུན་ཆུབ་པར་བྱེད་དམ། གཞན་དག་ལ་ཡང་རྒྱ་ཆེར་ཡང་དག་པར་རབ་ཏུ་སྟོན་ན། དེ་ཉིད་གཞི་དེ་ལས་བསོད་ནམས་ཆེས་མང་དུ་གྲངས་མེད་དཔག་ཏུ་མེད་པ་བསྐྱེད་དོ། །ཇི་ལྟར་ཡང་དག་པར་རབ་ཏུ་སྟོན་ཅེ་ན། ཇི་ལྟར་ཡང་དག་པར་རབ་ཏུ་མི་སྟོན་པ་བཞིན་དུ་སྟེ། དེས་ན་ཡང་དག་པར་རབ་ཏུ་སྟོན་པ་ཞེས་བྱའོ། །

            སྐར་མ་རབ་རིབ་མར་མེ་དང་། །སྒྱུ་མ་ཟིལ་པ་ཆུ་བུར་དང་། །རྨི་ལམ་གློག་དང་སྤྲིན་ལྟ་བུར། ། འདུས་བྱས་དེ་ལྟར་བལྟ་བར་བྱ། །

            བཅོམ་ལྡན་འདས་ཀྱིས་དེ་སྐད་ཅེས་བཀའ་སྩལ་ནས། གནས་བརྟན་རབ་འབྱོར་དང་། བྱང་ཆུབ་སེམས་དཔའ་དེ་དག་དང་། འཁོར་བཞི་པོ་དགེ་སློང་དང་། དགེ་སློང་མ་དང་། དགེ་བསྙེན་དང་། དགེ་བསྙེན་མ་དེ་དག་དང་། ལྷ་དང་། མི་དང་། ལྷ་མ་ཡིན་དང་། དྲི་ཟར་བཅས་པའི་འཇིག་རྟེན་ཡི་རངས་ཏེ། བཅོམ་ལྡན་འདས་ཀྱིས་གསུངས་པ་ལ་མངོན་པར་བསྟོད་དོ། །འཕགས་པ་ཤེས་རབ་ཀྱི་ཕ་རོལ་ཏུ་ཕྱིན་པ་རྡོ་རྗེ་གཅོད་པ་ཞེས་བྱ་བ་ཐེག་པ་ཆེན་པོའི་མདོ་རྫོགས་སོ།། །།
            """,
            english: """
            What the Tathagata calls a view of self is spoken of that way only because no such fixed view can be found there.

            The Blessed One said:
            “Subhuti, one who has truly entered the bodhisattva vehicle should know all dharmas, see all dharmas, and trust all dharmas in this way:
            without abiding even in the perception of dharmas.
            Why?
            Because what is called perception of dharmas is spoken of that way only because no fixed perception can be found there.”

            And if a great bodhisattva were to fill immeasurable, incalculable world-systems with the seven precious things and give them away, while another son or daughter of the lineage took even a four-line verse from this Perfection of Wisdom, held it, read it, practiced it fully, and taught it clearly to others, the latter would generate far greater merit.

            And how should it be taught rightly?
            As though there is no right teaching of it at all.
            That is what is called teaching it rightly.

            So should all conditioned things be seen:
            like a star at dawn,
            a blur in the eye,
            a lamp,
            an illusion,
            a drop of dew,
            a bubble,
            a dream,
            a flash of lightning,
            a cloud.

            When the Blessed One had spoken thus, the elder Subhuti, the bodhisattvas, the fourfold assembly of monks, nuns, laymen, and laywomen, together with gods, humans, asuras, and gandharvas, rejoiced and praised what the Blessed One had said.

            Thus is completed the Noble Great Vehicle Sutra called The Diamond-Cutter Perfection of Wisdom.
            """
        )
    ]
}
