import AppIntents

struct ClarityShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartClarityRecordingIntent(),
            phrases: [
                "Start recording in \(.applicationName)",
                "Record in \(.applicationName)",
                "Begin recording in \(.applicationName)"
            ],
            shortTitle: "Start recording",
            systemImageName: "mic.fill"
        )
    }
}
