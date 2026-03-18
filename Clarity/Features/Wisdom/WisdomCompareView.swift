import SwiftUI

struct WisdomCompareView: View {
    @EnvironmentObject private var flow: AppFlowRouter
    @Environment(\.dismiss) private var dismiss

    @AppStorage("wisdom_current_day_index")
    private var currentWisdomDayIndex: Int = 1

    @AppStorage("wisdom_last_completed_day_index")
    private var lastCompletedWisdomDayIndex: Int = 0

    @AppStorage("wisdom_last_done_day_key")
    private var lastDoneDayKey: String = ""

    let response: WisdomResponseEntity
    let prompt: WisdomPrompt

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var todayKey: String {
        Date().dayKey()
    }

    private var alreadyDoneToday: Bool {
        lastDoneDayKey == todayKey
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                questionCard
                answerCard
                compareCard
                doneCard
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
                body: prompt.buddhistView
            )

            Divider()

            compareSection(
                title: "Philosophical view",
                body: prompt.philosophicalView
            )

            Divider()

            compareSection(
                title: "Scientific view",
                body: prompt.scientificView
            )
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var doneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if alreadyDoneToday {
                Text("Today’s wisdom is already marked done.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                markDoneAndGoToProgress()
            } label: {
                Text("Completed for today")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(wisdomFill)
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

            Text(body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No comparison text available yet." : body)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markDoneAndGoToProgress() {
        if !alreadyDoneToday {
            lastDoneDayKey = todayKey
            lastCompletedWisdomDayIndex = max(lastCompletedWisdomDayIndex, currentWisdomDayIndex)
        }

        // Switch Home hub to Progress
        flow.openProgressWithBeadAnimation()

        // Pop back to Home hub so Progress is visible
        dismiss() // Compare -> Capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { dismiss() } // Capture -> Wisdom list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { dismiss() } // Wisdom list -> Home hub
    }
}
