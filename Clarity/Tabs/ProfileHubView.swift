import SwiftUI
import SwiftData

/// ProfileHubView
/// - Purpose: one place for "about me / configuration" surfaces.
/// - This is where Capsule + Settings live after collapsing tabs.
/// - Future (not wired yet): Progress / Petals, Community (Sangha), etc.
///
/// Design intent:
/// - Keep the tab bar action-oriented (Reflect / Focus / Practice).
/// - Keep identity/configuration in a single hub (Profile).
struct ProfileHubView: View {
    // Achievements counter (shared definition: completed turns)
    @Query private var completedTurns: [TurnEntity]

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    CapsuleView()
                } label: {
                    Label("Capsule", systemImage: "capsule")
                }

                // Optional: you already have this file; if you decide you don’t want it here,
                // delete this row later.
                NavigationLink {
                    CapsuleLearningView()
                } label: {
                    Label("Learning", systemImage: "sparkles")
                }
            } header: {
                Text("You")
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                NavigationLink {
                    PrivacyView()
                } label: {
                    Label("Privacy", systemImage: "hand.raised")
                }
            } header: {
                Text("App")
            }

            // Future placeholders (deliberately not wired yet)
            // Keeping these as comments avoids premature UX commitments.
            //
            // Section("Progress") {
            //     NavigationLink { ProgressView() } label: {
            //         Label("Lotus Bloom", systemImage: "circle.hexagonpath")
            //     }
            // }
            //
            // Section("Community") {
            //     NavigationLink { SanghaView() } label: {
            //         Label("Sangha", systemImage: "person.2")
            //     }
            // }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AchievementsView(openCount: min(108, completedTurns.count))
                } label: {
                    AchievementsCounterCapsule(count: min(108, completedTurns.count))
                }
                .accessibilityLabel(Text("Achievements: \(min(108, completedTurns.count)) of 108"))
            }
        }
    }
}


