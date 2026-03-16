import Foundation
import SwiftData

@Model
final class WisdomDailySetEntity {
    @Attribute(.unique) var dayKey: String

    var q1ID: UUID
    var q2ID: UUID
    var q3ID: UUID

    var selectedQuestionID: UUID?
    var completedAt: Date?

    init(
        dayKey: String,
        q1ID: UUID,
        q2ID: UUID,
        q3ID: UUID,
        selectedQuestionID: UUID? = nil,
        completedAt: Date? = nil
    ) {
        self.dayKey = dayKey
        self.q1ID = q1ID
        self.q2ID = q2ID
        self.q3ID = q3ID
        self.selectedQuestionID = selectedQuestionID
        self.completedAt = completedAt
    }
}
