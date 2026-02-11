// WelcomeManifest.swift

import Foundation

struct WelcomeManifest: Codable, Equatable {
    let dateKey: String
    let message: String
    let imageURL: String?
    let attribution: String?
}

