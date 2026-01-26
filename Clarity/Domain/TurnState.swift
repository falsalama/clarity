import Foundation

enum TurnState: String, Codable, CaseIterable, Sendable {
    case queued
    case recording
    case captured
    case transcribing
    case transcribedRaw
    case redacting
    case ready
    case readyPartial
    case interrupted
    case failed

    var isTerminal: Bool {
        switch self {
        case .ready, .readyPartial, .interrupted, .failed: return true
        default: return false
        }
    }
}

