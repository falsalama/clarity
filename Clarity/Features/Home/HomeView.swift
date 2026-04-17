import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @EnvironmentObject private var homeSurface: HomeSurfaceStore
    @EnvironmentObject private var flow: AppFlowRouter
    @Environment(\.scenePhase) private var scenePhase

    @State private var showWelcome: Bool = false
    @State private var didShowThisSession: Bool = false
    @State private var lastPresentedDayKey: String = Date().dayKey()

    var body: some View {
        Group {
            if showWelcome {
                WelcomeSurfaceView()
                    .ignoresSafeArea()
                    .onTapGesture { dismissWelcome() }
                    .toolbar(.hidden, for: .tabBar)
            } else {
                HomeHubView()
            }
        }
        .onAppear {
            presentWelcomeIfNeededForSession()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            presentWelcomeIfNeededForSession()
        }
    }

    private func presentWelcomeIfNeededForSession() {
        let todayKey = Date().dayKey()

        if lastPresentedDayKey != todayKey {
            lastPresentedDayKey = todayKey
            didShowThisSession = false
        }

        if flow.consumeHomeWelcomeSuppression() {
            didShowThisSession = true
            showWelcome = false
            lastPresentedDayKey = todayKey
            return
        }

        guard !didShowThisSession else { return }
        didShowThisSession = true
        lastPresentedDayKey = todayKey

        withAnimation(.easeInOut(duration: 0.18)) {
            showWelcome = true
        }
    }

    private func dismissWelcome() {
        homeSurface.markCurrentWelcomeSeen()

        withAnimation(.easeInOut(duration: 0.18)) {
            showWelcome = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            flow.homeHubEntrySeed += 1
        }
    }
}
