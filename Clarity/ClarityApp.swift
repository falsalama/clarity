import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(cloudTap)
                .environmentObject(capsuleStore)
                .environmentObject(redactionDictionary)
        }
        .modelContainer(
            for: [
                TurnEntity.self,
                RedactionRecordEntity.self,
                CapsuleEntity.self
            ]
        )
    }
}

