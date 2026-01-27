import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()

    init() {
        print("CloudTapBaseURL =", Bundle.main.object(forInfoDictionaryKey: "CloudTapBaseURL") ?? "nil")
        print("SupabaseURL =", Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") ?? "nil")
        print("SupabaseAnonKey =", (Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String)?.prefix(12) ?? "nil")
    }

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

