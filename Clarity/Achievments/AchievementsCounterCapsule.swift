import SwiftUI

/// Small counter pill used as the Achievements entry point.
///
/// Intentionally restrained: a simple capsule with a numeric count.
struct AchievementsCounterCapsule: View {
    let count: Int

    var body: some View {
        let shown = min(max(count, 0), 108)
        let goldFill = Color(red: 0.96, green: 0.82, blue: 0.26)

        Text("\(shown)")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(goldFill.opacity(0.90))
            .clipShape(Capsule())
    }
}
