import SwiftUI
import SwiftData

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var cloudTap = CloudTapSettings()
    @StateObject private var capsuleStore = CapsuleStore()
    @StateObject private var redactionDictionary = RedactionDictionary()
    @StateObject private var captureCoordinator = TurnCaptureCoordinator()
    @StateObject private var providerSettings = ContemplationProviderSettings()

    @State private var didBind = false
    @State private var pendingSiriStart = false
    @State private var siriTask: Task<Void, Never>? = nil

    private enum AppTab: Hashable {
        case capture, turns, capsule, settings
    }
    @State private var selectedTab: AppTab = .capture

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab_CaptureView()
                .tabItem { Label("Capture", systemImage: "mic") }
                .tag(AppTab.capture)

            NavigationStack { TurnsListView() }
                .tabItem { Label("Captures", systemImage: "tray.full") }
                .tag(AppTab.turns)

            NavigationStack { CapsuleView() }
                .tabItem { Label("Capsule", systemImage: "capsule") }
                .tag(AppTab.capsule)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .environmentObject(cloudTap)
        .environmentObject(capsuleStore)
        .environmentObject(redactionDictionary)
        .environmentObject(captureCoordinator)
        .environmentObject(providerSettings)
        .onAppear {
            guard !didBind else { return }
            didBind = true

            captureCoordinator.bind(
                modelContext: modelContext,
                dictionary: redactionDictionary,
                capsuleStore: capsuleStore
            )

            LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

            // If Siri set the flag before the UI was ready, mark pending.
            if SiriLaunchFlag.consumeStartCaptureRequest() {
                pendingSiriStart = true
            }

            // If we already appear and we're active, try.
            if scenePhase == .active {
                scheduleSiriStartIfNeeded()
            }
        }
        .onChange(of: scenePhase) {
            captureCoordinator.handleScenePhaseChange(scenePhase)

            if scenePhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

                // If Siri sets the flag while we're running, mark pending.
                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                }

                scheduleSiriStartIfNeeded()
            } else {
                // Cancel attempts while Siri/OS is bouncing lifecycle.
                siriTask?.cancel()
                siriTask = nil
            }
        }
    }

    private func scheduleSiriStartIfNeeded() {
        guard pendingSiriStart else { return }

        siriTask?.cancel()
        siriTask = Task { @MainActor in
            // Require the app to remain ACTIVE for a short window.
            // If scenePhase flips, this task will be cancelled by onChange.
            try? await Task.sleep(nanoseconds: 1_200_000_000)

            guard scenePhase == .active else { return }

            // One-shot consume.
            pendingSiriStart = false

            // Always show Capture tab.
            selectedTab = .capture
            try? await Task.sleep(nanoseconds: 150_000_000)

            // Attempt 1
            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }

            // Retry once if it immediately bounces back to idle.
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard scenePhase == .active else { return }
            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }
        }
    }
}
