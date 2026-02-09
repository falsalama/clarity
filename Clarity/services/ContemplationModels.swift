import Foundation

enum ContemplationMode: String, CaseIterable, Identifiable {
    case reflect
    case perspective
    case options
    case questions
    case talkItThrough

    var id: String { rawValue }
}

struct ContemplationRequest: Sendable {
    let mode: ContemplationMode
    let text: String
    let recordedAtISO: String?
    let appVersion: String
    let capsule: CloudTapCapsuleSnapshot?
    let previousResponseID: String?
}

struct ContemplationResponse: Sendable {
    let text: String
    let promptVersion: String
    let providerLane: ContemplationLane
}

enum ContemplationLane: String, Sendable {
    case local
    case onDevice
    case cloudTap
}
