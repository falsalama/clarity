import SwiftUI
import SwiftData

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Injected from ClarityApp.swift
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
    @EnvironmentObject private var capsuleStore: CapsuleStore
    @EnvironmentObject private var redactionDictionary: RedactionDictionary

    // First-run welcome splash gate
    @AppStorage("hasSeenWelcomeOverlay_v7") private var hasSeenWelcomeOverlay: Bool = false

    // Owned here
    @StateObject private var captureCoordinator = TurnCaptureCoordinator()
    @StateObject private var welcomeSurface = WelcomeSurfaceStore()

    @State private var didBind = false
    @State private var pendingSiriStart = false
    @State private var siriTask: Task<Void, Never>? = nil

    // Splash state
    @State private var showWelcomeSplash: Bool = false
    @State private var initialTabWhenSplashShown: AppTab? = nil
    @State private var ignoreTabChangesUntil: Date = .distantPast

    private enum AppTab: Hashable { case reflect, focus, practice, profile }
    @State private var selectedTab: AppTab = .reflect

    var body: some View {
        TabView(selection: $selectedTab) {

            tabRoot(Tab_CaptureView())
                .tabItem { Label("Reflect", systemImage: "mic") }
                .tag(AppTab.reflect)

            tabRoot(NavigationStack { FocusView() })
                .tabItem { Label("Focus", systemImage: "book.closed") }
                .tag(AppTab.focus)

            tabRoot(NavigationStack { PracticeView() })
                .tabItem { Label("Practice", systemImage: "leaf") }
                .tag(AppTab.practice)

            tabRoot(NavigationStack { ProfileHubView() })
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .environmentObject(captureCoordinator)
        .environmentObject(welcomeSurface)
        .onAppear {
            if !didBind {
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

                // Best-effort refresh of daily welcome surface.
                Task { await welcomeSurface.refreshIfNeeded() }
            }

            if !hasSeenWelcomeOverlay {
                showWelcomeSplash = true
                initialTabWhenSplashShown = selectedTab
                ignoreTabChangesUntil = Date().addingTimeInterval(0.35)
            } else {
                showWelcomeSplash = false
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            guard showWelcomeSplash else { return }
            guard Date() >= ignoreTabChangesUntil else { return }

            // Dismiss only if the user actually changed tabs.
            if let initial = initialTabWhenSplashShown, newTab != initial {
                dismissWelcomeSplash()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            captureCoordinator.handleScenePhaseChange(newPhase)

            if newPhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)
                Task { await welcomeSurface.refreshIfNeeded() }

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

    // MARK: - Tab wrapper (overlay lives INSIDE the tab content so the tab bar always stays on top)

    private func tabRoot<Content: View>(_ content: Content) -> some View {
        ZStack {
            content

            if showWelcomeSplash {
                // Tap anywhere dismisses (no fade). This overlay sits under the UIKit tab bar by construction.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { dismissWelcomeSplash() }
                    .ignoresSafeArea()

                WelcomeOverlayView(opacity: 1.0)
                    .environmentObject(welcomeSurface)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }

    private func dismissWelcomeSplash() {
        showWelcomeSplash = false
        hasSeenWelcomeOverlay = true
        initialTabWhenSplashShown = nil
    }

    // MARK: - Siri start handling

    private func scheduleSiriStartIfNeeded() {
        guard pendingSiriStart else { return }

        siriTask?.cancel()
        siriTask = Task { @MainActor in
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

