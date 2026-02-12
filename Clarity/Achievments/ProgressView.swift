// AchievementsView.swift

import SwiftUI

/// AchievementsView
///
/// v1:
/// - Supports legacy `openCount` (Reflect-only) so existing call sites keep working.
/// - Also supports full `reflectCount/focusCount/practiceCount`.
/// - Bloom (108 petals) is still driven by Reflect only for now.
struct AchievementsView: View {
    let reflectCount: Int
    let focusCount: Int
    let practiceCount: Int

    // Back-compat init (Reflect-only)
    init(openCount: Int) {
        self.reflectCount = openCount
        self.focusCount = 0
        self.practiceCount = 0
    }

    // Full init (future wiring)
    init(reflectCount: Int, focusCount: Int, practiceCount: Int) {
        self.reflectCount = reflectCount
        self.focusCount = focusCount
        self.practiceCount = practiceCount
    }

    private var clampedReflect: Int { min(max(reflectCount, 0), 108) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Bloom108View(openCount: clampedReflect)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(spacing: 10) {
                    Text("")
                        .font(.headline)

                    AchievementsCounterCapsule(
                        reflectCount: reflectCount,
                        focusCount: focusCount,
                        practiceCount: practiceCount
                    )

                    Text("\(clampedReflect) of 108")
                        .font(.title2.weight(.semibold))

                    Text("Bloom opens with Reflect captures. Focus and Practice will count once ‘Done’ is wired.")
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
