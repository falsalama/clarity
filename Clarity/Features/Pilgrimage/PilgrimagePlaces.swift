import Foundation
import CoreLocation

struct PilgrimagePlace: Identifiable {    let id: String
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let teaching: String
}

enum PilgrimagePlaces {

    /// Small curated seed list. Expand later (region packs etc).
    static let all: [PilgrimagePlace] = [
        PilgrimagePlace(
            id: "bodh_gaya",
            name: "Bodh Gaya",
            subtitle: "Awakening",
            coordinate: .init(latitude: 24.6950, longitude: 84.9910),
            teaching: "Not by force - by seeing. Let the grasping soften, then sit."
        ),
        PilgrimagePlace(
            id: "sarnath",
            name: "Sarnath",
            subtitle: "First turning",
            coordinate: .init(latitude: 25.3810, longitude: 83.0220),
            teaching: "Suffering is knowable. Its causes are workable. Keep it simple and direct."
        ),
        PilgrimagePlace(
            id: "kushinagar",
            name: "Kushinagar",
            subtitle: "Parinirvana",
            coordinate: .init(latitude: 26.7400, longitude: 83.8880),
            teaching: "Impermanence is not a problem. Clinging is the problem. Rest the mind."
        ),
        PilgrimagePlace(
            id: "samye",
            name: "Samye",
            subtitle: "First monastery in Tibet",
            coordinate: .init(latitude: 29.3076, longitude: 91.9956),
            teaching: "View comes alive when it meets practice. Translate the teaching into your day."
        ),
        PilgrimagePlace(
            id: "jokhang",
            name: "Jokhang",
            subtitle: "Heart of Lhasa",
            coordinate: .init(latitude: 29.6578, longitude: 91.1175),
            teaching: "Devotion is not submission. It is the mind recognising what it already knows."
        )
    ]
}
