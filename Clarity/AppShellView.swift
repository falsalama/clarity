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

    /// App-level primary tabs.
    /// - Reflect: capture + (soon) captures list entry point
    /// - Focus: teaching / explore surface (v0: LearningView)
    /// - Practice: tiny instruction surface (v0 placeholder for now)
    /// - Profile: hub for Capsule + Settings (+ future Progress / Community)
    private enum AppTab: Hashable {
        case reflect, focus, practice, profile
    }

    @State private var selectedTab: AppTab = .reflect

    var body: some View {
        TabView(selection: $selectedTab) {

            // Reflect (for now: existing capture tab view)
            Tab_CaptureView()
                .tabItem { Label("Reflect", systemImage: "mic") }
                .tag(AppTab.reflect)

            // Focus (for now: reuse existing LearningView as a v0 shell)
            NavigationStack { FocusView() }

                .tabItem { Label("Focus", systemImage: "book.closed") }
                .tag(AppTab.focus)

            // Practice (temporary placeholder, replaced next with real PracticeView.swift)
            NavigationStack { PracticeView() }

                .tabItem { Label("Practice", systemImage: "leaf") }
                .tag(AppTab.practice)

            // Profile (new hub)
            NavigationStack { ProfileHubView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
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

            // Always show Reflect tab (capture lives here).
            selectedTab = .reflect
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

// Temporary placeholder. Next step: replace with a real PracticeView.swift
private struct PracticePlaceholderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Practice")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming next: a very small instruction surface (v0).")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
    }
}

