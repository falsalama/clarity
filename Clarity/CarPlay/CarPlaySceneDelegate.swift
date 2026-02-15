// CarPlaySceneDelegate.swift

import Foundation
import CarPlay
import SwiftData
import UIKit

/// CarPlay entry point for Clarity (audio category).
/// Root UI is a tab bar:
/// - Captures (library list)
/// - Now Playing (system template)
///
/// With a tab bar root, we do NOT push Now Playing on selection.
/// Selection starts playback; user can switch to the Now Playing tab.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private let player = LocalAudioPlayer()

    private weak var interfaceController: CPInterfaceController?
    private var tabBarTemplate: CPTabBarTemplate?

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        self.interfaceController = interfaceController

        let captures = makeCapturesListTemplate()
        let nowPlaying = makeNowPlayingTemplate()

        let tabs = CPTabBarTemplate(templates: [captures, nowPlaying])
        tabBarTemplate = tabs

        interfaceController.setRootTemplate(tabs, animated: true, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        self.interfaceController = nil
        self.tabBarTemplate = nil
    }

    // MARK: - Templates

    private func makeCapturesListTemplate() -> CPListTemplate {
        let items = loadCaptureItems()

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Captures", sections: [section])

        template.tabTitle = "Captures"
        template.tabImage = UIImage(systemName: "waveform")

        return template
    }

    private func makeNowPlayingTemplate() -> CPNowPlayingTemplate {
        let template = CPNowPlayingTemplate.shared
        template.tabTitle = "Now Playing"
        template.tabImage = UIImage(systemName: "play.circle")
        return template
    }

    // MARK: - Data → List items

    private func loadCaptureItems() -> [CPListItem] {
        guard let container = AppServices.modelContainer else {
            return [CPListItem(text: "Data unavailable", detailText: "Model container not ready")]
        }

        let context = ModelContext(container)

        let descriptor = FetchDescriptor<TurnEntity>(
            predicate: #Predicate { t in
                t.audioPath != nil && t.audioBytes > 0
            },
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )

        let turns: [TurnEntity]
        do {
            turns = try context.fetch(descriptor)
        } catch {
            return [CPListItem(text: "Couldn’t load captures", detailText: "SwiftData fetch failed")]
        }

        if turns.isEmpty {
            return [CPListItem(text: "No recordings yet", detailText: "Make a capture on iPhone first")]
        }

        return turns.prefix(50).map { t in
            let title = normalizedTitle(for: t)
            let detail = formatCarPlayDetail(for: t)

            let item = CPListItem(text: title, detailText: detail)

            item.handler = { [weak self] _, completion in
                completion()
                guard let self else { return }

                // Start playback; user can switch to Now Playing tab.
                Task { @MainActor in
                    self.player.load(storedAudioPath: t.audioPath)
                    self.player.play()
                }
            }

            return item
        }
    }

    private func normalizedTitle(for t: TurnEntity) -> String {
        let raw = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Capture" : raw
    }

    private func formatCarPlayDetail(for t: TurnEntity) -> String {
        let date = DateFormatter.carPlayShort.string(from: t.recordedAt)
        if let d = t.durationSeconds, d > 0 {
            return "\(date) • \(formatDuration(d))"
        }
        return date
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded()))
        let m = s / 60
        let r = s % 60
        if m >= 60 {
            let h = m / 60
            let mm = m % 60
            return String(format: "%d:%02d:%02d", h, mm, r)
        }
        return String(format: "%d:%02d", m, r)
    }
}

private extension DateFormatter {
    static let carPlayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
