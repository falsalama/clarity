import SwiftUI
import SwiftData

/// FocusView (v0)
/// - Purpose: a gentle “thinking / understanding” surface.
/// - Not a curriculum, not a path selector.
/// - One short teaching at a time, optionally reflected on.
/// - Routes back into Reflect via normal capture (later we can prefill).
struct FocusView: View {

    // Achievements counter (shared definition: completed turns)
    @Query private var completedTurns: [TurnEntity]

    // v0: static rotation kept in-app.
    // Later this can come from local JSON or Cloud Tap.
    private let teachings: [Teaching] = [
        Teaching(
            title: "Training attention",
            body: """
Notice where the mind goes when it is not being directed.
There is no need to stop it or improve it.
Just see how it moves on its own.
""",
            prompt: "What do you notice about how your attention moves?"
        ),
        Teaching(
            title: "Working with change",
            body: """
Everything that appears also changes.
This includes thoughts, moods, and situations.
Nothing needs to be held in place.
""",
            prompt: "Where do you notice change happening right now?"
        ),
        Teaching(
            title: "Softening effort",
            body: """
Often we add effort on top of experience.
See what happens if effort relaxes slightly.
Nothing is lost.
""",
            prompt: "What eases when effort softens?"
        )
    ]

    @State private var teaching: Teaching

    init() {
        // Simple deterministic pick for now.
        // Later: date-based or Cloud Tap–driven.
        _teaching = State(initialValue: teachings.randomElement()!)

        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 12) {
                    Text(teaching.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(teaching.body)
                        .font(.body)

                    Divider()

                    Text(teaching.prompt)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Explicit hand-off, but no forced flow.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("If this brings something up, you can reflect on it.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Focus")
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

private struct Teaching {
    let title: String
    let body: String
    let prompt: String
}


