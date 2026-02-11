import Foundation
import SwiftData

/// Simple global handoff so non-SwiftUI entry points (eg CarPlay scene delegate)
/// can access the app’s SwiftData container.
enum AppServices {
    static var modelContainer: ModelContainer?
}
