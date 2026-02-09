import AppIntents

struct StartClarityRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start recording"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Keep this minimal. No audio/session work here.
        await MainActor.run {
            SiriLaunchFlag.requestStartCapture()
        }
        return .result()
    }
}

