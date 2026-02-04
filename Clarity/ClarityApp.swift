// ClarityApp.swift
import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()

    private let container: ModelContainer

    init() {
        print("CloudTapBaseURL =", Bundle.main.object(forInfoDictionaryKey: "CloudTapBaseURL") ?? "nil")
        print("SupabaseURL =", Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") ?? "nil")
        print("SupabaseAnonKey =", (Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String)?.prefix(12) ?? "nil")

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

            print("SwiftData store URL =", storeURL.path)
        } catch {
            fatalError("SwiftData container init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(cloudTap)
                .environmentObject(capsuleStore)
                .environmentObject(redactionDictionary)
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
