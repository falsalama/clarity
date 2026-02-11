// AppShellView.swift

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
    @EnvironmentObject private var welcomeSurface: WelcomeSurfaceStore

    // Owned here
    @StateObject private var captureCoordinator = TurnCaptureCoordinator()

    @State private var didBind = false
    @State private var pendingSiriStart = false
    @State private var siriTask: Task<Void, Never>? = nil

    // Tab bar fade (launch-only)
    @State private var tabBar: UITabBar? = nil
    @State private var didFadeTabBarThisLaunch: Bool = false

    private enum AppTab: Hashable { case home, reflect, focus, practice, profile }
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            Tab_CaptureView()
                .tabItem { Label("Reflect", systemImage: "mic") }
                .tag(AppTab.reflect)

            NavigationStack { FocusView() }
                .tabItem { Label("Focus", systemImage: "book.closed") }
                .tag(AppTab.focus)

            NavigationStack { PracticeView() }
                .tabItem { Label("Practice", systemImage: "leaf") }
                .tag(AppTab.practice)

            NavigationStack { ProfileHubView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .environmentObject(captureCoordinator)
        .environmentObject(welcomeSurface)
        .background(
            TabBarReader { bar in
                self.tabBar = bar
                self.fadeTabBarInIfNeeded()
            }
            .frame(width: 0, height: 0)
        )
        .onAppear {
            guard !didBind else { return }
            didBind = true

            captureCoordinator.bind(
                modelContext: modelContext,
                dictionary: redactionDictionary,
                capsuleStore: capsuleStore
            )

            LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

            if SiriLaunchFlag.consumeStartCaptureRequest() {
                pendingSiriStart = true
                selectedTab = .reflect
            }

            if scenePhase == .active {
                scheduleSiriStartIfNeeded()
            }

            fadeTabBarInIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            captureCoordinator.handleScenePhaseChange(newPhase)

            if newPhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                    selectedTab = .reflect
                }

                scheduleSiriStartIfNeeded()
            } else {
                siriTask?.cancel()
                siriTask = nil
            }
        }
    }

    // MARK: - Tab bar fade

    private func fadeTabBarInIfNeeded() {
        guard !didFadeTabBarThisLaunch else { return }
        guard let bar = tabBar else { return }
        didFadeTabBarThisLaunch = true

        DispatchQueue.main.async {
            bar.alpha = 0.0
            UIView.animate(
                withDuration: 0.55,
                delay: 0.08,
                options: [.curveEaseOut, .beginFromCurrentState]
            ) {
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
        guard let bar = tabBarController?.tabBar else { return }
        didResolve = true
        onResolve(bar)
    }
}

