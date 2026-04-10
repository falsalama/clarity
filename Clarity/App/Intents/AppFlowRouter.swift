import Combine

@MainActor
final class AppFlowRouter: ObservableObject {

    enum Tab: Hashable {
        case home
        case reflect
        case meditation
        case explore
        case profile
    }

    enum HomeTab: Hashable {
        case practice
        case progress
    }

    @Published var homeTab: HomeTab = .practice
    @Published var selectedTab: Tab = .home
    @Published var pendingOpenProgress: Bool = false
    @Published var animateNextBead: Bool = false
    @Published var homeHubEntrySeed: Int = 0
    @Published var homeNavigationResetSeed: Int = 0
    @Published var suppressNextHomeWelcome: Bool = false

    func go(_ tab: Tab) {
        selectedTab = tab
    }
    func openPracticeHome() {
        pendingOpenProgress = false
        selectedTab = .home
        homeTab = .practice
    }

    func openPracticeHomeAtRoot() {
        pendingOpenProgress = false
        selectedTab = .home
        homeTab = .practice
        suppressNextHomeWelcome = true
        homeNavigationResetSeed += 1
    }
    
    func openProgressWithBeadAnimation() {
        selectedTab = .home
        homeTab = .progress
        pendingOpenProgress = true
        animateNextBead = true
        suppressNextHomeWelcome = true
        homeNavigationResetSeed += 1
    }

    func consumeProgressTrigger() {
        pendingOpenProgress = false
    }

    func consumeBeadAnimationFlag() {
        animateNextBead = false
    }

    func consumeHomeWelcomeSuppression() -> Bool {
        let shouldSuppress = suppressNextHomeWelcome
        suppressNextHomeWelcome = false
        return shouldSuppress
    }
}
