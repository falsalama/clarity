import SwiftUI

struct WisdomCompareView: View {
    let response: WisdomResponseEntity

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                questionCard
                answerCard
                compareCard
            }
            .padding(16)
        }
        .background {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                WisdomBackgroundWaterView()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Compare Views")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question")
                .font(.headline)
                .foregroundStyle(wisdomFill)

            Text(response.questionText)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if !response.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(response.promptText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your answer")
                .font(.headline)
                .foregroundStyle(wisdomFill)

            Text(response.answerText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var compareCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            compareSection(
                title: "Buddhist view",
                body: "This answer can now be compared with Buddhist reasoning and contemplative analysis."
            )

            Divider()

            compareSection(
                title: "Philosophical view",
                body: "This answer can now be compared with philosophical perspectives on identity, language, causality, or appearance."
            )

            Divider()

            compareSection(
                title: "Scientific view",
                body: "This answer can now be compared with modern cognitive, psychological, or scientific perspectives where relevant."
            )
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(wisdomFill)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
