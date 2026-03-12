import SwiftUI

struct WisdomCaptureView: View {
    let dailySet: WisdomDailySet
    let lane: WisdomLane

    @State private var captureMode: WisdomCaptureMode = .text
    @State private var typedText: String = ""
    @State private var voiceTranscriptDraft: String = ""

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var question: WisdomQuestion {
        dailySet.question(for: lane)
    }

    private var currentAnswerText: String {
        switch captureMode {
        case .text:
            return typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .voice:
            return voiceTranscriptDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var canContinue: Bool {
        currentAnswerText.isEmpty == false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                questionCard
                modeCard
                answerCard
                continueCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(lane.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lane.title)
                    .font(.headline)
                    .foregroundStyle(wisdomFill)

                Spacer()

                Text(question.sourceTheme.replacingOccurrences(of: "-", with: " "))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(question.questionText)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(question.promptText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capture")
                .font(.headline)

            Picker("Capture mode", selection: $captureMode) {
                Text("Write").tag(WisdomCaptureMode.text)
                Text("Voice").tag(WisdomCaptureMode.voice)
            }
            .pickerStyle(.segmented)

            Text("This is the Wisdom-specific answer flow. Shared mic, transcript, WAL, trace, and learning can plug in here next.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var answerCard: some View {
        switch captureMode {
        case .text:
            textAnswerCard
        case .voice:
            voiceAnswerCard
        }
    }

    private var textAnswerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your answer")
                .font(.headline)

            editorShell(text: $typedText, placeholder: "Write your answer here.")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var voiceAnswerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(wisdomFill)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Voice transcript")
                        .font(.subheadline.weight(.semibold))

                    Text("For now this is a placeholder transcript field so the route stays stable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            editorShell(text: $voiceTranscriptDraft, placeholder: "Transcript will appear here.")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var continueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                WisdomCompareView(
                    dailySet: dailySet,
                    lane: lane,
                    answerText: currentAnswerText
                )
            } label: {
                Text("See other views")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(wisdomFill)
            .disabled(!canContinue)

            Text("Saving for today comes next, once the route is stable.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func editorShell(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }

            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 180)
                .background(Color.clear)
        }
    }
}

private struct WisdomCompareView: View {
    let dailySet: WisdomDailySet
    let lane: WisdomLane
    let answerText: String

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var question: WisdomQuestion {
        dailySet.question(for: lane)
    }

    private var lenses: [WisdomLens] {
        dailySet.lenses(for: lane)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Question")
                        .font(.headline)

                    Text(question.questionText)
                        .font(.title3.weight(.semibold))
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your answer")
                        .font(.headline)

                    Text(answerText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Other views")
                        .font(.headline)

                    ForEach(lenses) { lens in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lens.kind.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(wisdomFill)

                            Text(lens.body)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)

                        if lens.id != lenses.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Other Views")
        .navigationBarTitleDisplayMode(.inline)
    }
}
