import Foundation

enum TurnSource: String, Codable, CaseIterable, Sendable {
    case captured
    case importedAudio
    case importedText
}

enum CaptureContext: String, Codable, CaseIterable, Sendable {
    case handheld
    case handsfree
    case carplay
    case intent
    case unknown

    var isDriving: Bool { self == .carplay }
}

enum TranscriptionProvider: String, Codable, Sendable {
    case appleSpeechOnDevice
    case appleSpeechServer
    case unknown
}

enum ReflectProvider: String, Codable, Sendable {
    case none
    case appleOnDevice
    case cloudTap
}

struct TurnError: Codable, Sendable, Equatable {
    var domain: String
    var code: Int
    var userFacingKey: String?
    var debugMessage: String?
}

