import Combine

@MainActor
final class AppFlowRouter: ObservableObject {

    enum Tab: Hashable {
        case home, reflect, focus, practice, profile
    }

    @Published var selectedTab: Tab = .home

    // When Practice completes, flip to Profile and auto-open Progress once.
    @Published var pendingOpenProgress: Bool = false

    // Used to animate “one new bead” when Progress opens right after completion.
    @Published var animateNextBead: Bool = false

    func go(_ tab: Tab) { selectedTab = tab }

    func openProgressWithBeadAnimation() {
        selectedTab = .profile
        pendingOpenProgress = true
        animateNextBead = true
    }

    func consumeProgressTrigger() {
        pendingOpenProgress = false
        // animateNextBead stays true until Progress consumes it.
    }

    func consumeBeadAnimationFlag() {
        animateNextBead = false
    }
}
