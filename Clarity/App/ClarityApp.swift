import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var clarityReflect = ClarityReflectStore()
    @StateObject private var providerSettings = ContemplationProviderSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()
    @StateObject private var homeSurfaceStore = HomeSurfaceStore()
    @StateObject private var supabaseAuth = SupabaseAuthStore()
    @StateObject private var nowPlaying = NowPlayingStore.shared

    private let container: ModelContainer

    init() {
#if DEBUG
        print("CloudTapBaseURL =",
              Bundle.main.object(forInfoDictionaryKey: "CloudTapBaseURL") ?? "nil")
        print("SupabaseURL =",
              Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") ?? "nil")
        print("SupabaseAnonKey =",
              (Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String)?.prefix(12) ?? "nil")
        print("HomeSurfaceEndpoint =",
              Bundle.main.object(forInfoDictionaryKey: "HOME_SURFACE_ENDPOINT")
              ?? Bundle.main.object(forInfoDictionaryKey: "HomeSurfaceEndpoint")
              ?? Bundle.main.object(forInfoDictionaryKey: "WelcomeManifestEndpoint")
              ?? Bundle.main.object(forInfoDictionaryKey: "WELCOME_MANIFEST_ENDPOINT")
              ?? "nil")
#endif

        Self.cleanupLegacyLocalModelStorageIfNeeded()

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
                FocusCompletionEntity.self,
                PracticeCompletionEntity.self,
                ReflectCompletionEntity.self,
                PilgrimageVisitEntity.self,
                UserProfileEntity.self,
                FocusProgramStateEntity.self,
                PracticeProgramStateEntity.self,
                ReflectProgramStateEntity.self,
                WisdomQuestionEntity.self,
                WisdomDailySetEntity.self,
                WisdomResponseEntity.self,
                configurations: config
            )

            AppServices.modelContainer = self.container

#if DEBUG
            print("SwiftData store URL =", storeURL.path)
#endif
        } catch {
            fatalError("SwiftData container init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(cloudTap)
                .environmentObject(clarityReflect)
                .environmentObject(providerSettings)
                .environmentObject(capsuleStore)
                .environmentObject(redactionDictionary)
                .environmentObject(homeSurfaceStore)
                .environmentObject(supabaseAuth)
                .environmentObject(nowPlaying)
                .task {
                    await clarityReflect.prepare()
                }
               
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

    private static func cleanupLegacyLocalModelStorageIfNeeded() {
        let key = "legacy.local.model.storage.cleaned.v1"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }

        defer { defaults.set(true, forKey: key) }

        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        let fileName = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        let modelFiles = [
            appSupport.appendingPathComponent("models", isDirectory: true).appendingPathComponent(fileName),
            appSupport.appendingPathComponent("Models", isDirectory: true).appendingPathComponent(fileName)
        ]

        for url in modelFiles where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
            removeDirectoryIfEmpty(url.deletingLastPathComponent())
        }
    }

    private static func removeDirectoryIfEmpty(_ url: URL) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        ), contents.isEmpty else {
            return
        }

        try? FileManager.default.removeItem(at: url)
    }
}
