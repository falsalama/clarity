// TalkMessage.swift
import Foundation

enum TalkRole: String, Codable, Sendable {
    case user
    case assistant
}

struct TalkMessage: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var role: TalkRole
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), role: TalkRole, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

