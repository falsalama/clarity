import SwiftUI
import SwiftData
import UIKit

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Injected from ClarityApp.swift
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
    @EnvironmentObject private var capsuleStore: CapsuleStore
    @EnvironmentObject private var redactionDictionary: RedactionDictionary

    // First-run welcome splash gate
    @AppStorage("hasSeenWelcomeOverlay_v9") private var hasSeenWelcomeOverlay: Bool = false

    // DEBUG ONLY — keep false in normal builds
    private let FORCE_SPLASH_DEBUG: Bool = true

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

    // Tab bar fade-in
    @State private var tabBar: UITabBar? = nil
    @State private var didRunTabBarFadeThisLaunch: Bool = false

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

        // Bind + show splash once
        .onAppear {
            if !didBind {
                didBind = true

                captureCoordinator.bind(
                    modelContext: modelContext,
                    dictionary: redactionDictionary,
                    capsuleStore: capsuleStore
                )

                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                }

                if scenePhase == .active {
                    scheduleSiriStartIfNeeded()
                }
            }

            // Splash gate
            if FORCE_SPLASH_DEBUG || !hasSeenWelcomeOverlay {
                showWelcomeSplash = true
                initialTabWhenSplashShown = selectedTab
                ignoreTabChangesUntil = Date().addingTimeInterval(0.35)
                maybeStartTabBarFade()
            } else {
                showWelcomeSplash = false
                tabBar?.alpha = 1.0
            }
        }

        // Fetch manifest + image (runs once per view lifetime)
        .task {
            await welcomeSurface.refreshIfNeeded()
        }

        // Dismiss splash when user switches tab (optional behaviour)
        .onChange(of: selectedTab) { _, newTab in
            guard showWelcomeSplash || FORCE_SPLASH_DEBUG else { return }
            guard Date() >= ignoreTabChangesUntil else { return }

            if let initial = initialTabWhenSplashShown, newTab != initial {
                dismissWelcomeSplash()
            }
        }

        // Refresh when app becomes active
        .onChange(of: scenePhase) { _, newPhase in
            captureCoordinator.handleScenePhaseChange(newPhase)

            if newPhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)
                Task { await welcomeSurface.refreshIfNeeded() }

                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                }

                scheduleSiriStartIfNeeded()
            } else {
                siriTask?.cancel()
                siriTask = nil
            }
        }
    }

    // MARK: - Tab wrapper (overlay lives INSIDE tab content so tab bar stays on top)

    private func tabRoot<Content: View>(_ content: Content) -> some View {
        ZStack {
            content

            if showWelcomeSplash || FORCE_SPLASH_DEBUG {
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
        .background(
            TabBarReader { bar in
                self.tabBar = bar
                self.maybeStartTabBarFade()
            }
            .frame(width: 0, height: 0)
        )
    }

    private func dismissWelcomeSplash() {
        showWelcomeSplash = false
        if !FORCE_SPLASH_DEBUG {
            hasSeenWelcomeOverlay = true
        }
        initialTabWhenSplashShown = nil
        tabBar?.alpha = 1.0
    }

    private func maybeStartTabBarFade() {
        guard (showWelcomeSplash || FORCE_SPLASH_DEBUG) else { return }
        guard !didRunTabBarFadeThisLaunch else { return }
        guard let bar = tabBar else { return }

        didRunTabBarFadeThisLaunch = true

        DispatchQueue.main.async {
            bar.alpha = 0.12
            UIView.animate(withDuration: 0.65, delay: 0.05, options: [.curveEaseOut, .beginFromCurrentState]) {
                bar.alpha = 1.0
            }
        }
    }

    // MARK: - Siri start handling

    private func scheduleSiriStartIfNeeded() {
        guard pendingSiriStart else { return }

        siriTask?.cancel()
        siriTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard scenePhase == .active else { return }

            pendingSiriStart = false

            selectedTab = .reflect
            try? await Task.sleep(nanoseconds: 150_000_000)

            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }

            try? await Task.sleep(nanoseconds: 900_000_000)
            guard scenePhase == .active else { return }
            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }
        }
    }
}

// MARK: - UITabBar resolver

private struct TabBarReader: UIViewControllerRepresentable {
    let onResolve: (UITabBar) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ResolverViewController(onResolve: onResolve)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class ResolverViewController: UIViewController {
    private let onResolve: (UITabBar) -> Void
    private var didResolve = false

    init(onResolve: @escaping (UITabBar) -> Void) {
        self.onResolve = onResolve
        super.init(nibName: nil, bundle: nil)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resolveOnce()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resolveOnce()
    }

    private func resolveOnce() {
        guard !didResolve else { return }
        guard let tabBar = tabBarController?.tabBar else { return }
        didResolve = true
        onResolve(tabBar)
    }
}

