// PilgrimagePlaces.swift

import Foundation
import CoreLocation

struct PilgrimagePlace: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let teaching: String
}

/// NOTE:
/// - Keep ids stable (used for visits).
/// - Coordinates are “best effort”; a few modern centres may be approximate - adjust if you want precision.
enum PilgrimagePlaces {

    static let all: [PilgrimagePlace] = [

        // ─────────────────────────────
        // INDIA - BUDDHA PLACES
        // ─────────────────────────────

        PilgrimagePlace(
            id: "mahabodhi_temple",
            name: "Mahabodhi Temple",
            subtitle: "Bodh Gaya - Awakening",
            coordinate: .init(latitude: 24.6950, longitude: 84.9910),
            teaching: "Not by force - by seeing. Let grasping soften, then sit."
        ),

        PilgrimagePlace(
            id: "bodhi_tree",
            name: "Bodhi Tree",
            subtitle: "Vajrasana precinct",
            coordinate: .init(latitude: 24.6953, longitude: 84.9912),
            teaching: "Do not add a self to what is already complete."
        ),

        PilgrimagePlace(
            id: "vajrasana",
            name: "Vajrasana (Diamond Throne)",
            subtitle: "Mahabodhi precinct",
            coordinate: .init(latitude: 24.6952, longitude: 84.9911),
            teaching: "Presence is the practice. No extra stance required."
        ),

        PilgrimagePlace(
            id: "sarnath",
            name: "Sarnath",
            subtitle: "First Turning",
            coordinate: .init(latitude: 25.3810, longitude: 83.0220),
            teaching: "Suffering is workable. Keep it direct."
        ),

        PilgrimagePlace(
            id: "kushinagar",
            name: "Kushinagar",
            subtitle: "Parinirvana",
            coordinate: .init(latitude: 26.7400, longitude: 83.8900),
            teaching: "Everything ends. Let ending be clean."
        ),

        PilgrimagePlace(
            id: "nalanda_ruins",
            name: "Nalanda Ruins",
            subtitle: "Ancient University",
            coordinate: .init(latitude: 25.1360, longitude: 85.4440),
            teaching: "Study cuts fixation when it serves liberation."
        ),

        PilgrimagePlace(
            id: "rajgir_vulture_peak",
            name: "Vulture Peak",
            subtitle: "Rajgir",
            coordinate: .init(latitude: 25.0280, longitude: 85.4200),
            teaching: "Form is empty - as lived perception."
        ),

        // ─────────────────────────────
        // INDIA - VAJRAYANA / HIMALAYA
        // ─────────────────────────────

        PilgrimagePlace(
            id: "tsuglagkhang_dharamsala",
            name: "Tsuglagkhang Complex",
            subtitle: "Dharamsala",
            coordinate: .init(latitude: 32.2396, longitude: 76.3219),
            teaching: "Exile clarifies what truly matters."
        ),

        PilgrimagePlace(
            id: "tso_pema_rewalsar",
            name: "Tso Pema (Rewalsar Lake)",
            subtitle: "Himachal Pradesh - Guru Rinpoche",
            coordinate: .init(latitude: 31.5236, longitude: 76.8228),
            teaching: "Blessing is the softening of the hard edges."
        ),

        // ─────────────────────────────
        // NEPAL - KATHMANDU VALLEY
        // ─────────────────────────────

        PilgrimagePlace(
            id: "boudhanath",
            name: "Boudhanath Stupa",
            subtitle: "Kathmandu",
            coordinate: .init(latitude: 27.7215, longitude: 85.3620),
            teaching: "Circumambulation - thoughts loosen without debate."
        ),

        PilgrimagePlace(
            id: "swayambhunath",
            name: "Swayambhunath Stupa",
            subtitle: "Kathmandu",
            coordinate: .init(latitude: 27.7143, longitude: 85.2903),
            teaching: "High view - low clinging."
        ),

        PilgrimagePlace(
            id: "pharping",
            name: "Pharping",
            subtitle: "Kathmandu Valley - practice caves",
            coordinate: .init(latitude: 27.6308, longitude: 85.2746),
            teaching: "Practice is private. Results show up later."
        ),

        // ─────────────────────────────
        // TIBET / HIMALAYA - CORE SITES
        // ─────────────────────────────

        PilgrimagePlace(
            id: "samye",
            name: "Samye Monastery",
            subtitle: "First monastery in Tibet",
            coordinate: .init(latitude: 29.2650, longitude: 91.3790),
            teaching: "Transmission lives in application."
        ),

        PilgrimagePlace(
            id: "chimpu_caves",
            name: "Chimpu Caves",
            subtitle: "Retreat area above Samye",
            coordinate: .init(latitude: 29.2800, longitude: 91.4100),
            teaching: "Rest without fabrication."
        ),

        PilgrimagePlace(
            id: "jokhang",
            name: "Jokhang Temple",
            subtitle: "Lhasa",
            coordinate: .init(latitude: 29.6578, longitude: 91.1326),
            teaching: "Devotion without theatre - simply show up."
        ),

        PilgrimagePlace(
            id: "potala",
            name: "Potala Palace",
            subtitle: "Lhasa",
            coordinate: .init(latitude: 29.6579, longitude: 91.1173),
            teaching: "Power fades. Practice remains."
        ),

        PilgrimagePlace(
            id: "ganden",
            name: "Ganden Monastery",
            subtitle: "Near Lhasa",
            coordinate: .init(latitude: 29.7430, longitude: 91.7230),
            teaching: "Study stabilises when pride dissolves."
        ),

        PilgrimagePlace(
            id: "tsurphu",
            name: "Tsurphu Monastery",
            subtitle: "Seat of the Karmapas",
            coordinate: .init(latitude: 29.8700, longitude: 90.3420),
            teaching: "Continuity through practice, not identity."
        ),

        PilgrimagePlace(
            id: "sakya",
            name: "Sakya Monastery",
            subtitle: "Shigatse region",
            coordinate: .init(latitude: 28.9000, longitude: 89.9000), // approx
            teaching: "Keep the view clean - methods work better."
        ),

        PilgrimagePlace(
            id: "dingri",
            name: "Dingri",
            subtitle: "High plateau - southern U-Tsang",
            coordinate: .init(latitude: 28.6500, longitude: 87.8500), // approx
            teaching: "High altitude - fewer distractions, fewer stories."
        ),

        PilgrimagePlace(
            id: "kailash",
            name: "Gang Rinpoche (Mount Kailash)",
            subtitle: "Ngari",
            coordinate: .init(latitude: 31.0670, longitude: 81.3120), // approx
            teaching: "Do the kora - not to gain, but to give up."
        ),

        PilgrimagePlace(
            id: "dzogchen_monastery",
            name: "Dzogchen Monastery",
            subtitle: "Kham (Derge region)",
            coordinate: .init(latitude: 31.8000, longitude: 99.0000), // approx
            teaching: "Directness is not abruptness - it is simplicity."
        ),

        // ─────────────────────────────
        // BHUTAN
        // ─────────────────────────────

        PilgrimagePlace(
            id: "paro_taktsang",
            name: "Paro Taktsang",
            subtitle: "Tiger’s Nest - Bhutan",
            coordinate: .init(latitude: 27.4916, longitude: 89.3633),
            teaching: "Devotion steady, without display."
        ),

        PilgrimagePlace(
            id: "punakha_dzong",
            name: "Punakha Dzong",
            subtitle: "Bhutan",
            coordinate: .init(latitude: 27.5917, longitude: 89.8774),
            teaching: "Bliss is not excitement - it is unclenching."
        ),

        // ─────────────────────────────
        // THAILAND
        // ─────────────────────────────

        PilgrimagePlace(
            id: "wat_pho",
            name: "Wat Pho",
            subtitle: "Bangkok",
            coordinate: .init(latitude: 13.7466, longitude: 100.4930),
            teaching: "Body practice can be Dharma."
        ),

        PilgrimagePlace(
            id: "wat_arun",
            name: "Wat Arun",
            subtitle: "Bangkok",
            coordinate: .init(latitude: 13.7437, longitude: 100.4889),
            teaching: "Rising light, empty centre."
        ),

        // ─────────────────────────────
        // CAMBODIA
        // ─────────────────────────────

        PilgrimagePlace(
            id: "angkor_wat",
            name: "Angkor Wat",
            subtitle: "Cambodia",
            coordinate: .init(latitude: 13.4125, longitude: 103.8670),
            teaching: "Impermanence at monumental scale."
        ),

        // ─────────────────────────────
        // MYANMAR (BURMA)
        // ─────────────────────────────

        PilgrimagePlace(
            id: "shwedagon",
            name: "Shwedagon Pagoda",
            subtitle: "Yangon",
            coordinate: .init(latitude: 16.7986, longitude: 96.1490),
            teaching: "Keep it simple: bow, walk, notice."
        ),

        PilgrimagePlace(
            id: "mahamuni",
            name: "Mahamuni Buddha Temple",
            subtitle: "Mandalay",
            coordinate: .init(latitude: 21.9160, longitude: 96.0550), // approx
            teaching: "Faith is not belief - it is returning."
        ),

        PilgrimagePlace(
            id: "kyaiktiyo",
            name: "Kyaiktiyo (Golden Rock)",
            subtitle: "Mon State",
            coordinate: .init(latitude: 17.4810, longitude: 97.0980), // approx
            teaching: "Let effort be quiet. Let mind be quieter."
        ),

        // ─────────────────────────────
        // JAPAN
        // ─────────────────────────────

        PilgrimagePlace(
            id: "sensoji",
            name: "Sensō-ji",
            subtitle: "Tokyo",
            coordinate: .init(latitude: 35.7148, longitude: 139.7967),
            teaching: "Ritual can be a clean container for mind."
        ),

        PilgrimagePlace(
            id: "mount_koya",
            name: "Mount Kōya (Kōyasan)",
            subtitle: "Wakayama",
            coordinate: .init(latitude: 34.2130, longitude: 135.5860),
            teaching: "When the world quiets, practice deepens."
        ),

        // ─────────────────────────────
        // EUROPE - DZOGCHEN COMMUNITY / RETREAT
        // ─────────────────────────────

        PilgrimagePlace(
            id: "osel_ling_spain",
            name: "Osel Ling",
            subtitle: "Sierra Nevada, Spain",
            coordinate: .init(latitude: 36.9330, longitude: -3.3870),
            teaching: "Retreat sharpens what the world blunts."
        ),

        PilgrimagePlace(
            id: "dzamling_gar_tenerife",
            name: "Dzamling Gar",
            subtitle: "Tenerife - Dzogchen Community",
            coordinate: .init(latitude: 28.2916, longitude: -16.6291),
            teaching: "View before method."
        ),

        PilgrimagePlace(
            id: "merigar_west",
            name: "Merigar West",
            subtitle: "Italy - Dzogchen Community",
            coordinate: .init(latitude: 42.9250, longitude: 11.5550), // approx
            teaching: "Direct introduction must be lived."
        ),

        PilgrimagePlace(
            id: "tashigar_sur",
            name: "Tashigar Sur",
            subtitle: "Costa Rica - Dzogchen Community",
            coordinate: .init(latitude: 10.1760, longitude: -84.5630), // approx
            teaching: "Natural awareness needs no decoration."
        ),

        // ─────────────────────────────
        // UK - CENTRES
        // ─────────────────────────────

        PilgrimagePlace(
            id: "samye_ling",
            name: "Kagyu Samye Ling",
            subtitle: "Scotland",
            coordinate: .init(latitude: 55.2985, longitude: -3.2089),
            teaching: "Continuity is built by returning."
        ),

        PilgrimagePlace(
            id: "kagyu_samye_dzong_london",
            name: "Kagyu Samye Dzong",
            subtitle: "London",
            coordinate: .init(latitude: 51.5030, longitude: -0.0700), // approx
            teaching: "A city seat - practice without needing conditions."
        ),

        PilgrimagePlace(
            id: "marpa_house",
            name: "Marpa House",
            subtitle: "Ashdon, Essex (UK)",
            coordinate: .init(latitude: 52.0350, longitude: 0.2850), // approx
            teaching: "A quiet place to practise without performance."
        ),

        // ─────────────────────────────
        // USA - PLACEHOLDERS (refine later)
        // ─────────────────────────────

        PilgrimagePlace(
            id: "sf_zen_center",
            name: "San Francisco Zen Center",
            subtitle: "California (placeholder)",
            coordinate: .init(latitude: 37.7750, longitude: -122.4190), // approx
            teaching: "Ordinary mind - not ordinary habits."
        ),

        PilgrimagePlace(
            id: "portland_center",
            name: "Portland Dharma Centre",
            subtitle: "Oregon (placeholder)",
            coordinate: .init(latitude: 45.5152, longitude: -122.6784),
            teaching: "Keep showing up. That’s the whole trick."
        )
    ]
}
