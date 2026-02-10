import SwiftUI

struct WelcomeOverlayView: View {
    @EnvironmentObject private var store: WelcomeSurfaceStore

    let opacity: Double

    var body: some View {
        ZStack {
            // Plain, calm surface
            Color(.systemBackground)

            VStack(spacing: 14) {
                Text("Welcome")
                    .font(.system(size: 52, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
                    .opacity(0.85)

                // Optional small subline if/when you want it (kept minimal)
                // Uncomment later if desired.
                /*
                Text(store.manifest?.message ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                */
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(opacity)
    }
}

