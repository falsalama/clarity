import SwiftUI
import SwiftData

/// PracticeView (v0)
/// - Goal: a tiny, non-performative instruction surface.
/// - Not a timer app, not a streak driver, not “more is better”.
/// - Keeps the tone permissive and light.
/// - Future: could rotate a few micro-practices; could optionally log “returned”.
struct PracticeView: View {
    // Achievements counter (shared definition: completed turns)
    @Query private var completedTurns: [TurnEntity]
    // v0: fixed micro-practice. Keep it simple and safe.
    private let title = "Practice"
    private let instruction = """
Take three natural breaths.
Nothing to fix. Nothing to achieve.
Just notice the next inhale, then the next exhale.
"""

    @State private var isExpanded = true

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Small “card” feel without over-design.
                VStack(alignment: .leading, spacing: 10) {
                    Text("A tiny practice")
                        .font(.headline)

                    Text(instruction)
                        .font(.body)
                        .foregroundStyle(.primary)

                    // Optional collapse to keep it from feeling like a “task”.
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Hide" : "Show")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Gentle optional note - not a journal prompt, not tracking.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("If anything is still pulling at you, switch to Reflect.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle(title)
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
        .onChange(of: isExpanded) { _, newValue in
            // v0 behaviour: just collapse/expand the card. Nothing else.
            // (Keeping this hook in case we later want haptics/logging.)
            _ = newValue
        }
    }
}


