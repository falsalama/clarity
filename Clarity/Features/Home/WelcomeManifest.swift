// WelcomeManifest.swift

import Foundation

struct WelcomeManifest: Codable, Equatable {
    let dateKey: String
    let message: String
    let imageURL: String?
    let attribution: String?

    // Optional, server-driven tab subtitles (camelCase to match current decoder)
    let focusSubtitle: String?
    let practiceSubtitle: String?
}
