import Foundation
import SwiftData

@Model
final class WisdomQuestionEntity {
    @Attribute(.unique) var id: UUID
    var text: String
    var difficulty: Int
    var category: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        difficulty: Int = 1,
        category: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.difficulty = difficulty
        self.category = category
        self.createdAt = createdAt
    }
}
