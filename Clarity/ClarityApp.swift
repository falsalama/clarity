import SwiftUI
import SwiftData

@main
struct ClarityApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var providerSettings = ContemplationProviderSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()
    @StateObject private var welcomeSurfaceStore = WelcomeSurfaceStore()

    private let container: ModelContainer

    init() {
        print("CloudTapBaseURL =",
              Bundle.main.object(forInfoDictionaryKey: "CloudTapBaseURL") ?? "nil")
        print("SupabaseURL =",
              Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") ?? "nil")
        print("SupabaseAnonKey =",
              (Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String)?.prefix(12) ?? "nil")
        print("WelcomeManifestEndpoint =",
              Bundle.main.object(forInfoDictionaryKey: "WELCOME_MANIFEST_ENDPOINT") ?? "nil")

        do {
            let storeURL = try Self.storeURL(filename: "clarity.store")

            let config = ModelConfiguration(
                url: storeURL,
                cloudKitDatabase: .none
            )

            self.container = try ModelContainer(
                for: TurnEntity.self,
                RedactionRecordEntity.self,
                CapsuleEntity.self,
                PatternStatsEntity.self,
                configurations: config
            )

            // IMPORTANT: make container available to CarPlay scene delegate.
            AppServices.modelContainer = self.container

            print("SwiftData store URL =", storeURL.path)
        } catch {
            fatalError("SwiftData container init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(cloudTap)
                .environmentObject(providerSettings)
                .environmentObject(capsuleStore)
                .environmentObject(redactionDictionary)
                .environmentObject(welcomeSurfaceStore)
        }
        .modelContainer(container)
    }

    private static func storeURL(filename: String) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dir = base.appendingPathComponent("Clarity", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir.appendingPathComponent(filename)
    }
}

