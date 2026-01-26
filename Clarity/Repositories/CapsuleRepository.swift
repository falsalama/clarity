import Foundation

protocol CapsuleRepository: Sendable {
    func loadCapsule() throws -> Capsule
    func saveCapsule(_ capsule: Capsule) throws
    func resetLearnedProfile() throws
    func setLearningEnabled(_ enabled: Bool) throws
}

