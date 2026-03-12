import SwiftUI

struct GuidanceHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                waysToEngageCard
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

                    Text("one-to-one practice support")
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

    private var waysToEngageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ways to Engage")
                .font(.headline)

            VStack(spacing: 12) {
                guidanceLink(
                    title: "One-to-One",
                    subtitle: "Personal guidance sessions."
                )

                guidanceLink(
                    title: "Meditation Lessons",
                    subtitle: "Private meditation instruction."
                )

                guidanceLink(
                    title: "Expert Guidance",
                    subtitle: "Learn from experienced practitioners."
                )

                guidanceLink(
                    title: "Counselling",
                    subtitle: "Professional one-to-one support."
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
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

    private func guidanceLink(title: String, subtitle: String) -> some View {
        NavigationLink {
            GuidancePlaceholderView(
                title: title,
                subtitle: subtitle
            )
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
        }
    }
}

private struct GuidancePlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
