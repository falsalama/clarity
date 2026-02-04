import Foundation
import SwiftUI

enum FeatureFlags {
    // Internal developer/runtime toggle. Not user-facing.
#if DEBUG
    @AppStorage("feature.localWALBuildEnabled")
    static var localWALBuildEnabled: Bool = true
#else
    @AppStorage("feature.localWALBuildEnabled")
    static var localWALBuildEnabled: Bool = false
#endif
}
