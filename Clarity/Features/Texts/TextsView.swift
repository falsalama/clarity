import SwiftUI

struct TextsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerBlock

                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink {
                        PechaReaderView(
                            title: HeartSutraPecha.title,
                            subtitle: HeartSutraPecha.subtitle,
                            pages: HeartSutraPecha.pages
                        )
                    } label: {
                        TextCard(
                            title: "Heart Sutra",
                            subtitle: "Pecha edition",
                            category: "Sutra"
                        )
                    }
                    .buttonStyle(.plain)

                    TextCard(
                        title: "Refuge Prayer",
                        subtitle: "Coming soon",
                        category: "Prayer"
                    )

                    TextCard(
                        title: "Dedication Prayer",
                        subtitle: "Coming soon",
                        category: "Prayer"
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Texts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Texts")
                .font(.title2.weight(.semibold))

            Text("A small library for sutras, prayers, and recitations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

private struct TextCard: View {
    let title: String
    let subtitle: String
    let category: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(category)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
