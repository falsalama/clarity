import Foundation
import SwiftData

enum AppServices {
    static var modelContainer: ModelContainer?

    // Supabase anonymous-auth cache for non-SwiftUI services.
    static var supabaseAccessToken: String?
    static var supabaseUserID: String?
}
