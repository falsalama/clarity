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
    @EnvironmentObject private var homeSurface: HomeSurfaceStore

    // Owned here
    @StateObject private var captureCoordinator = TurnCaptureCoordinator()
    @StateObject private var flow = AppFlowRouter()

    @State private var didBind = false
    @State private var pendingSiriStart = false
    @State private var siriTask: Task<Void, Never>? = nil

    init() {
        // Ensure the tab bar is opaque and styled from the very first frame.
        Self.configureGlobalTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $flow.selectedTab) {

            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppFlowRouter.Tab.home)

            NavigationStack { CaptureView(hideDailyQuestion: true) }
                .tabItem { Label("Reflect", systemImage: "mic") }
                .tag(AppFlowRouter.Tab.reflect)

            NavigationStack { FocusView() }
                .tabItem { Label("View", systemImage: "book.closed") }
                .tag(AppFlowRouter.Tab.focus)

            NavigationStack { PracticeView() }
                .tabItem { Label("Practice", systemImage: "leaf") }
                .tag(AppFlowRouter.Tab.practice)

            NavigationStack { ProfileHubView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppFlowRouter.Tab.profile)
        }
        .environmentObject(flow)
        .environmentObject(captureCoordinator)
        .environmentObject(homeSurface)
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
                flow.selectedTab = .reflect
            }

            if scenePhase == .active {
                scheduleSiriStartIfNeeded()
            }

            // Start daily scheduling + refresh once at launch
            homeSurface.startDailyAutoRefresh()
            Task { await homeSurface.refreshNow() }
        }
        // IMPORTANT: this 1-arg closure fixes your current compiler error
        .onChange(of: scenePhase) { _, newPhase in            captureCoordinator.handleScenePhaseChange(newPhase)

            if newPhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                    flow.selectedTab = .reflect
                }

                scheduleSiriStartIfNeeded()

                // Refresh when returning to foreground (not on tab switches)
                homeSurface.startDailyAutoRefresh()
                Task { await homeSurface.refreshNow() }

            } else {
                siriTask?.cancel()
                siriTask = nil
                homeSurface.stopDailyAutoRefresh()
            }
        }
    }

    // MARK: - Fixed tab bar appearance

    private static func configureGlobalTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Let the content behind influence the feel again (like before).
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.10)

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
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

            flow.selectedTab = .reflect
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
