import SwiftUI
import SwiftData
import UIKit

struct WisdomPromptCaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator
    @Environment(\.modelContext) private var modelContext

    let prompt: WisdomPrompt

    @State private var typedText: String = ""
    @State private var voiceTranscriptDraft: String = ""
    @State private var selectedInput: WisdomInputMode? = nil
    @State private var savedResponse: WisdomResponseEntity?
    @State private var existingResponse: WisdomResponseEntity?
    @State private var showCompare = false

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var currentAnswerText: String {
        switch selectedInput {
        case .text:
            return typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .voice:
            return voiceTranscriptDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        case .none:
            return ""
        }
    }

    private var todayKey: String {
        let cal = Calendar.current
        let d = cal.startOfDay(for: Date())
        let y = cal.component(.year, from: d)
        let m = cal.component(.month, from: d)
        let day = cal.component(.day, from: d)
        return String(format: "%04d-%02d-%02d", y, m, day)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                questionCard
                captureCard
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
        .navigationTitle(prompt.category)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingResponseIfNeeded()
        }
        .onChange(of: coordinator.lastCompletedTurnID) { _, newValue in
            guard let id = newValue else { return }
            absorbCompletedTurn(id)
        }
        .navigationDestination(isPresented: $showCompare) {
            if let savedResponse {
                WisdomCompareView(response: savedResponse, prompt: prompt)
            }
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(prompt.category)
                    .font(.headline)
                    .foregroundStyle(wisdomFill)

                Spacer()
            }

            Text(prompt.question)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if !prompt.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(prompt.prompt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your answer")
                .font(.headline)

            SharedCaptureSurfaceView(
                showPromptChips: false,
                showTypeButton: true,
                onTypeTap: {
                    selectedInput = .text
                }
            )

            if let selectedInput {
                answerPreviewCard(for: selectedInput)
            }

            Button {
                saveResponseAndGoToCompare()
            } label: {
                Text("Compare views")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(wisdomFill)
            .disabled(currentAnswerText.isEmpty)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func answerPreviewCard(for mode: WisdomInputMode) -> some View {
        switch mode {
        case .text:
            VStack(alignment: .leading, spacing: 12) {
                Text("Typed answer")
                    .font(.headline)

                editorShell(text: $typedText, placeholder: "Write your answer here.")
            }

        case .voice:
            VStack(alignment: .leading, spacing: 12) {
                Text("Transcript")
                    .font(.headline)

                editorShell(text: $voiceTranscriptDraft, placeholder: "Transcript will appear here.")
            }
        }
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

    private func loadExistingResponseIfNeeded() {
        let dayKey = todayKey
        let questionID = prompt.id

        let descriptor = FetchDescriptor<WisdomResponseEntity>(
            predicate: #Predicate<WisdomResponseEntity> {
                $0.dayKey == dayKey && $0.questionID == questionID
            }
        )

        guard let existing = try? modelContext.fetch(descriptor).first else { return }

        existingResponse = existing
        savedResponse = existing

        if let typed = existing.typedText,
           !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectedInput = .text
            typedText = typed
            return
        }

        if let transcript = existing.redactedTranscript,
           !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectedInput = .voice
            voiceTranscriptDraft = transcript
            return
        }

        if !existing.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectedInput = .text
            typedText = existing.answerText
        }
    }

    private func absorbCompletedTurn(_ id: UUID) {
        let descriptor = FetchDescriptor<TurnEntity>(
            predicate: #Predicate<TurnEntity> { $0.id == id }
        )

        guard let turn = try? modelContext.fetch(descriptor).first else { return }

        let redacted = turn.transcriptRedactedActive.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = (turn.transcriptRaw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bestText = redacted.isEmpty ? raw : redacted

        guard !bestText.isEmpty else { return }

        selectedInput = .voice
        voiceTranscriptDraft = bestText

        coordinator.clearLiveTranscript()
        coordinator.lastCompletedTurnID = nil
    }

    private func saveResponseAndGoToCompare() {
        let mode = selectedInput ?? .text

        if let existingResponse {
            existingResponse.captureModeRaw = mode.rawValue
            existingResponse.answerText = currentAnswerText
            existingResponse.typedText = mode == .text ? typedText : nil
            existingResponse.rawTranscript = mode == .voice ? voiceTranscriptDraft : nil
            existingResponse.redactedTranscript = mode == .voice ? voiceTranscriptDraft : nil
            existingResponse.completedAt = .now

            do {
                try modelContext.save()
                savedResponse = existingResponse
                showCompare = true
            } catch {
                print("WISDOM UPDATE SAVE FAILED: \(error)")
            }
            return
        }

        let response = WisdomResponseEntity(
            dayKey: todayKey,
            setID: "direct_prompt",
            setTitle: "Wisdom",
            questionID: prompt.id,
            laneRaw: "opening",
            questionText: prompt.question,
            promptText: prompt.prompt,
            sourceTheme: prompt.category.lowercased(),
            captureModeRaw: mode.rawValue,
            answerText: currentAnswerText,
            typedText: mode == .text ? typedText : nil,
            rawTranscript: mode == .voice ? voiceTranscriptDraft : nil,
            redactedTranscript: mode == .voice ? voiceTranscriptDraft : nil
        )

        modelContext.insert(response)

        do {
            try modelContext.save()
            existingResponse = response
            savedResponse = response
            showCompare = true
        } catch {
            print("WISDOM INSERT SAVE FAILED: \(error)")
        }
    }
}

enum WisdomInputMode: String, CaseIterable {
    case text
    case voice
}
