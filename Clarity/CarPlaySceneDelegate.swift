import Foundation
import CarPlay
import SwiftData
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private let player = LocalAudioPlayer()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        let list = makeRootListTemplate(interfaceController: interfaceController)

        // iOS 14+ API (non-deprecated)
        interfaceController.setRootTemplate(list, animated: true, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        // no-op for now
    }

    // MARK: - Templates

    private func makeRootListTemplate(interfaceController: CPInterfaceController) -> CPListTemplate {
        let items = loadCaptureItems(interfaceController: interfaceController)

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Clarity", sections: [section])

        template.tabTitle = "Clarity"
        template.tabImage = UIImage(systemName: "waveform")

        return template
    }

    private func loadCaptureItems(interfaceController: CPInterfaceController) -> [CPListItem] {
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
            let title = t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Capture" : t.title
            let detail = formatCarPlayDetail(for: t)

            let item = CPListItem(text: title, detailText: detail)

            item.handler = { [weak self] _, completion in
                defer { completion() }
                guard let self else { return }

                self.player.load(storedAudioPath: t.audioPath)

                if self.player.lastError == nil {
                    self.player.play()
                    interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                }
            }

            return item
        }
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

