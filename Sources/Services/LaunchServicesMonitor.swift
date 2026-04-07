import Foundation

/// Monitors the LaunchServices plist for changes and fires a callback.
/// This lets us auto-refresh the UI when the user confirms a dialog.
final class LaunchServicesMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChange: () -> Void

    private static let plistPath: String = {
        NSHomeDirectory() + "/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
    }()

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func start() {
        stop()
        openAndWatch()
    }

    func stop() {
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func openAndWatch() {
        fileDescriptor = open(Self.plistPath, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: DispatchQueue.main
        )

        source?.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = self.source?.data ?? []

            self.onChange()

            // If the file was renamed or deleted (atomic replace), re-open
            if flags.contains(.rename) || flags.contains(.delete) {
                self.stop()
                // Brief delay for the new file to be written
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.openAndWatch()
                }
            }
        }

        source?.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source?.resume()
    }

    deinit {
        stop()
    }
}
