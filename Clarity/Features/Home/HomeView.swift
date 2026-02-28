import SwiftUI

/// Home wrapper:
/// - Welcome shows on each fresh app open (once per session)
/// - Welcome shows again on each new day (once per day)
/// - Welcome dismisses by tapping anywhere
/// - Welcome is NOT inside NavigationStack (prevents white/nav chrome)
struct HomeView: View {
    @EnvironmentObject private var homeSurface: HomeSurfaceStore

    @AppStorage("welcome_surface_last_seen_daykey")
    private var lastSeenWelcomeDayKey: String = ""

    @State private var showWelcome: Bool = false
    @State private var didShowThisSession: Bool = false

    private var todayKey: String { Date().dayKey() }

    var body: some View {
        Group {
            if showWelcome {
                WelcomeSurfaceView()
                    .ignoresSafeArea()
                    .onTapGesture { dismissWelcome() }
                    .toolbar(.hidden, for: .tabBar)
            } else {
                // Hub content is inside a NavigationStack provided by AppShellView.
                HomeHubView()
            }
        }
        .onAppear {
            presentWelcomeIfNeededForSession()
        }
        .onChange(of: homeSurface.manifest?.dateKey) { _, newKey in
            let key = newKey ?? todayKey
            if lastSeenWelcomeDayKey != key {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showWelcome = true
                }
            }
        }
    }

    private func presentWelcomeIfNeededForSession() {
        guard !didShowThisSession else { return }
        didShowThisSession = true

        withAnimation(.easeInOut(duration: 0.18)) {
            showWelcome = true
        }
    }

    private func dismissWelcome() {
        let key = homeSurface.manifest?.dateKey ?? todayKey
        lastSeenWelcomeDayKey = key

        withAnimation(.easeInOut(duration: 0.18)) {
            showWelcome = false
        }
    }
}
