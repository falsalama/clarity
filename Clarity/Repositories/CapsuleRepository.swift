import Foundation

protocol CapsuleRepository: Sendable {
    func loadCapsule() throws -> CapsuleModel
    func saveCapsule(_ capsule: CapsuleModel) throws
    func resetLearnedProfile() throws
    func setLearningEnabled(_ enabled: Bool) throws
}

