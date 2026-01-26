import Foundation

enum FileStore {
    static func removeIfExists(atPath path: String?) {
        guard let path, !path.isEmpty else { return }
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }
        try? fm.removeItem(at: url)
    }
}

