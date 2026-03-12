import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                contentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clarity")
                .font(.headline)

            Text("A Buddhist daily practice app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text("How it works")
                .font(.subheadline.weight(.semibold))

            Text("Begin each day by pressing Start daily practice.")
                .font(.footnote)

            Text("One practice has three parts:")
                .font(.footnote.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Reflect - Answer one question honestly by audio or text.")
                Text("View - A short teaching to contemplate.")
                Text("Practice - A method to cultivate inner space.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Divider()

            Text("Complete all three to form one unit of practice. These slowly advance over time. Return each day to build continuity.")
                .font(.footnote.weight(.semibold))

            Divider()

            Text("Reflect")
                .font(.subheadline.weight(.semibold))

            Text("Reflect is a private thinking instrument. It combines structured reflection with a Buddhist-informed AI assistant designed to help clarify experience rather than analyse or judge it.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("You can speak or write freely. The system helps organise thoughts, reveal patterns, and support clear seeing.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("On-device mode is fully private. Optional Cloud Tap processing uses redacted, anonymous text for deeper model responses.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Capsule")
                .font(.subheadline.weight(.semibold))

            Text("Capsule is your adaptive learning layer. If enabled, it gradually tailors questions and teachings to your patterns over time. Capsule stores structure, not secrets.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Note")
                .font(.subheadline.weight(.semibold))

            Text("This app is not therapy and does not replace a teacher. It is a structured instrument for contemplative training.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(alignment: .topTrailing) {
                    Image("clarityMark")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 950, height: 950)
                        .opacity(0.12)
                        .offset(x: 140, y: -260)
                        .allowsHitTesting(false)
                }
                .clipped()
        )
    }
}
