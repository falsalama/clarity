import SwiftUI

struct AboutView: View {
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 14) {
                contentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clarity")
                .font(.headline)

            Text("A Buddhist daily practice app for reflection, study, and continuity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text("Daily practice")
                .font(.subheadline.weight(.semibold))

            Text("Each day begins with a simple practice flow designed to build continuity rather than intensity.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Reflect: answer one daily question by voice or text.")
                Text("View: receive a short contemplation or teaching.")
                Text("Practice: complete the day with a structured method.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("Completing the cycle builds one unit of practice and gradually advances your progress over time.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Daily reflections")
                .font(.subheadline.weight(.semibold))

            Text("Reflect is a private space for clarifying experience. Wisdom and Compassion add separate daily contemplations, each with their own question or response space.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("You can speak or write freely. The app is designed to support clear seeing rather than judgement or performance.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("On-device mode is fully private. Optional Cloud Tap processing uses redacted, anonymous text for deeper model responses.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Texts, sounds, and calendar")
                .font(.subheadline.weight(.semibold))

            Text("Clarity also includes a growing library of texts, audio practice spaces, and a calendar feed that can surface observances or special days inside the app.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Capsule")
                .font(.subheadline.weight(.semibold))

            Text("Capsule is your adaptive learning layer. If enabled, it gradually tailors questions and teachings to your patterns over time. Capsule stores structure, not secrets.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.22))
                .overlay(alignment: .topTrailing) {
                    Image("clarityMark")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 950, height: 950)
                        .opacity(0.10)
                        .offset(x: 140, y: -260)
                        .allowsHitTesting(false)
                }
                .clipped()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }
}
