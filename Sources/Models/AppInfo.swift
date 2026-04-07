import Foundation
import AppKit

/// An installed application and the file types it claims.
struct AppInfo: Identifiable, Hashable {
    let id: String  // bundle ID (e.g. "com.microsoft.VSCode")
    let name: String
    let path: String
    let claimedTypes: [ClaimedType]
    let icon: NSImage?

    struct ClaimedType: Hashable {
        let uti: String
        let extensions: [String]
        let name: String
    }

    var claimedExtensionCount: Int {
        claimedTypes.reduce(0) { $0 + $1.extensions.count }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}
