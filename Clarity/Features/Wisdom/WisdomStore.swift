import Foundation
import Combine

struct WisdomStepsResponse: Codable, Equatable {
    let dayIndex: Int
    let items: [WisdomPrompt]
}

@MainActor
final class WisdomStore: ObservableObject {
    @Published private(set) var response: WisdomStepsResponse? = nil

    private(set) var endpointURL: URL? = nil

    private let fm = FileManager.default

    init() {
        endpointURL = Self.readEndpointURLFromPlist()
        loadCached()
    }

    func refreshNow() async {
        guard let endpointURL else { return }

        do {
            var req = URLRequest(url: endpointURL)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(WisdomStepsResponse.self, from: data)
            self.response = decoded
            try persistResponse(data)
        } catch {
            // silent for now; fallback stays in the view
        }
    }

    var todaysItems: [WisdomPrompt] {
        response?.items ?? []
    }

    private static func readEndpointURLFromPlist() -> URL? {
        let keys = [
            "WISDOM_STEPS_ENDPOINT",
            "WisdomStepsEndpoint"
        ]

        for key in keys {
            if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
               raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {

                let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = URL(string: cleaned) {
                    return url
                }
            }
        }
        return nil
    }

    private func baseDir() -> URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Wisdom", isDirectory: true)
        if fm.fileExists(atPath: dir.path) == false {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func responsePath() -> URL {
        baseDir().appendingPathComponent("wisdom_steps.json")
    }

    private func loadCached() {
        guard
            let data = try? Data(contentsOf: responsePath()),
            let cached = try? JSONDecoder().decode(WisdomStepsResponse.self, from: data)
        else {
            response = nil
            return
        }

        response = cached
    }

    private func persistResponse(_ data: Data) throws {
        try data.write(to: responsePath(), options: [.atomic])
    }
}
