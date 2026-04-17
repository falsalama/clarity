// CarPlaySceneDelegate.swift

import Foundation
import CarPlay
import SwiftUI
import UIKit

/// CarPlay entry point for Clarity (audio category).
/// Root UI is a tab bar:
/// - Sounds (library list)
/// - Now Playing (system template)
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private let player = NowPlayingStore.shared

    private weak var interfaceController: CPInterfaceController?
    private var tabBarTemplate: CPTabBarTemplate?

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        self.interfaceController = interfaceController

        let sounds = makeSoundsListTemplate()
        let nowPlaying = makeNowPlayingTemplate()

        let tabs = CPTabBarTemplate(templates: [sounds, nowPlaying])
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

    private func makeSoundsListTemplate() -> CPListTemplate {
        let items = loadSoundItems()

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Sounds", sections: [section])

        template.tabTitle = "Sounds"
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

    private func loadSoundItems() -> [CPListItem] {
        FocusSoundsLibrary.all.map { sound in
            let item = CPListItem(
                text: sound.title,
                detailText: "\(sound.subtitle) • \(sound.durationLabel)"
            )

            item.handler = { [weak self] _, completion in
                completion()
                guard let self else { return }

                Task { @MainActor in
                    if self.player.currentItem?.id == sound.id {
                        if self.player.isPlaying {
                            return
                        }
                        self.player.resume()
                    } else {
                        self.player.play(sound, queue: FocusSoundsLibrary.all)
                    }
                }
            }

            return item
        }
    }
}
