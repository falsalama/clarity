// CloudTapStepsModels.swift

import Foundation

struct CloudTapStepsResponse: Decodable {
    let programmeSlug: String
    let count: Int
    let maxVersion: Int
    let steps: [CloudTapStep]
}

struct CloudTapStep: Decodable {
    let stepIndex: Int
    let title: String
    let body: String
    let tags: [String]?
    let version: Int?
}
