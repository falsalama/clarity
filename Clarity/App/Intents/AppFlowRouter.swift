import Combine

@MainActor
final class AppFlowRouter: ObservableObject {

    enum Tab: Hashable {
        case home
        case reflect
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

    func go(_ tab: Tab) {
        selectedTab = tab
    }

    func openProgressWithBeadAnimation() {
        selectedTab = .home
        homeTab = .progress
        pendingOpenProgress = true
        animateNextBead = true
    }

    func consumeProgressTrigger() {
        pendingOpenProgress = false
    }

    func consumeBeadAnimationFlag() {
        animateNextBead = false
    }
}
