import SwiftUI

/// AchievementsView
///
/// v0: a single progress motif (moon seat + 108 petals) driven by openCount.
///
/// - Not a tab.
/// - Entered via the top-right counter button.
struct AchievementsView: View {
    let openCount: Int

    private var clamped: Int { min(max(openCount, 0), 108) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Bloom108View(openCount: clamped)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(spacing: 8) {
                    Text("Moon seat")
                        .font(.headline)

                    Text("\(clamped) of 108")
                        .font(.title2.weight(.semibold))

                    Text("Opens as captures complete. No streaks. No pressure.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer(minLength: 10)
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
