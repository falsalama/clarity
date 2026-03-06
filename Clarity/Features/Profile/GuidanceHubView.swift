import SwiftUI

struct GuidanceHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                supportCard
                futureCard
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.06),
                    Color.clear,
                    Color.blue.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Guidance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Guidance")
                        .font(.headline)

                    Text("Teachings and one-to-one practice support")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Teachings and one-to-one practice support")
                .font(.title3.weight(.semibold))

            Text("This space will connect people with authentic teachers and practitioners for practice questions, life guidance, meditation support, and future lessons.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Purpose")
                .font(.headline)

            Text("The aim is to support living traditions, monasteries, nunneries, and serious practitioners - beginning with English and Tibetan, and later expanding across other languages and regions.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var futureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coming later")
                .font(.headline)

            Text("This page can later hold a teacher image, a short welcome video, lesson offerings, and session booking - without changing the destination or navigation model.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
