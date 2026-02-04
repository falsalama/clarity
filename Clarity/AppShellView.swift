// AppShellView.swift
import SwiftUI
import SwiftData

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()

    @StateObject private var captureCoordinator = TurnCaptureCoordinator()

    var body: some View {
        TabView {
            Tab_CaptureView()
                .tabItem { Label("Capture", systemImage: "mic") }


            NavigationStack {
                TurnsListView()
            }
            .tabItem { Label("Captures", systemImage: "tray.full") }

            NavigationStack {
                CapsuleView()
            }
            .tabItem { Label("Capsule", systemImage: "capsule") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environmentObject(cloudTap)
        .environmentObject(capsuleStore)
        .environmentObject(redactionDictionary)
        .environmentObject(captureCoordinator)
        .onAppear {
            captureCoordinator.bind(
                modelContext: modelContext,
                dictionary: redactionDictionary,
                capsuleStore: capsuleStore
            )
            // Initial projection refresh (idempotent)
            LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)
        }
        .onChange(of: scenePhase) { _, newValue in
            captureCoordinator.handleScenePhaseChange(newValue)
            if newValue == .active {
                // Foreground refresh so decay/ordering is current
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)
            }
        }
    }
}
