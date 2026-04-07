import SwiftUI

/// Displays an app name with its icon.
struct AppLabel: View {
    let name: String
    let icon: NSImage?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            Text(name)
                .lineLimit(1)
        }
    }
}
