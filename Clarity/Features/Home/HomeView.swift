import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @EnvironmentObject private var homeSurface: HomeSurfaceStore
    @EnvironmentObject private var flow: AppFlowRouter

    @State private var showWelcome: Bool = false
    @State private var didShowThisSession: Bool = false

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
    }

    private func presentWelcomeIfNeededForSession() {
        if flow.consumeHomeWelcomeSuppression() {
            didShowThisSession = true
            showWelcome = false
            return
        }

        guard !didShowThisSession else { return }
        didShowThisSession = true

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
