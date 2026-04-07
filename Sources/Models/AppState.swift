import Foundation
import SwiftUI
import CoreServices

@MainActor
final class AppState: ObservableObject {
    @Published var fileTypes: [FileTypeInfo] = []
    @Published var installedApps: [AppInfo] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFileTypes: Set<String> = []

    // Reassignment state
    @Published var isReassigning = false
    @Published var reassignProgress: Int = 0
    @Published var reassignTotal: Int = 0
    @Published var reassignErrors: [String] = []

    // Auto-confirm state
    @Published var autoConfirmEnabled = false {
        didSet { updateAutoConfirm() }
    }

    private nonisolated let service = FileTypeService()
    private var monitor: LaunchServicesMonitor?
    private let autoConfirm = DialogAutoConfirm()

    // Debounce timer for file monitoring refresh
    private var refreshDebounce: Task<Void, Never>?

    /// Filtered file types based on search text.
    var filteredFileTypes: [FileTypeInfo] {
        guard !searchText.isEmpty else { return fileTypes }
        let query = searchText.lowercased()
        return fileTypes.filter { ft in
            ft.extensions.contains { $0.lowercased().contains(query) }
            || ft.description.lowercased().contains(query)
            || ft.id.lowercased().contains(query)
            || ft.defaultEditorName.lowercased().contains(query)
            || ft.defaultViewerName.lowercased().contains(query)
        }
    }

    var appsByClaimCount: [AppInfo] {
        installedApps
            .filter { !$0.claimedTypes.isEmpty }
            .sorted { $0.claimedTypes.count > $1.claimedTypes.count }
    }

    func loadData() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            let apps = await Task.detached {
                self.service.scanInstalledApps()
            }.value

            var types = await Task.detached {
                self.service.discoverFileTypes(from: apps)
            }.value

            let appLookup = Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0.name) })
            for i in types.indices {
                types[i].defaultEditorName = types[i].defaultEditor.flatMap { appLookup[$0] }
                    ?? types[i].defaultEditor?.components(separatedBy: ".").last?.capitalized
                    ?? "None"
                types[i].defaultViewerName = types[i].defaultViewer.flatMap { appLookup[$0] }
                    ?? types[i].defaultViewer?.components(separatedBy: ".").last?.capitalized
                    ?? "None"
            }

            self.installedApps = apps
            self.fileTypes = types
            self.isLoading = false

            // Start monitoring for changes
            startMonitoring()
        }
    }

    /// Refresh only the handler assignments (faster than full reload).
    func refreshHandlers() {
        Task {
            var updatedTypes = self.fileTypes
            let appLookup = Dictionary(uniqueKeysWithValues: installedApps.map { ($0.id, $0.name) })

            await Task.detached {
                for i in updatedTypes.indices {
                    let uti = updatedTypes[i].id
                    updatedTypes[i].defaultViewer = self.service.defaultHandler(for: uti, role: .viewer)
                    updatedTypes[i].defaultEditor = self.service.defaultHandler(for: uti, role: .editor)
                    updatedTypes[i].allHandlers = self.service.allHandlers(for: uti)

                    updatedTypes[i].defaultEditorName = updatedTypes[i].defaultEditor.flatMap { appLookup[$0] }
                        ?? updatedTypes[i].defaultEditor?.components(separatedBy: ".").last?.capitalized
                        ?? "None"
                    updatedTypes[i].defaultViewerName = updatedTypes[i].defaultViewer.flatMap { appLookup[$0] }
                        ?? updatedTypes[i].defaultViewer?.components(separatedBy: ".").last?.capitalized
                        ?? "None"
                }
            }.value

            self.fileTypes = updatedTypes
        }
    }

    func appName(for bundleID: String?) -> String {
        guard let bundleID else { return "None" }
        if let app = installedApps.first(where: { $0.id == bundleID }) {
            return app.name
        }
        return bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
    }

    func appIcon(for bundleID: String?) -> NSImage? {
        guard let bundleID else { return nil }
        return installedApps.first(where: { $0.id == bundleID })?.icon
    }

    func commonHandlers(for utis: Set<String>) -> [String] {
        let types = utis.compactMap { uti in
            fileTypes.first { $0.id == uti }
        }
        guard let first = types.first else { return [] }
        var common = Set(first.allHandlers)
        for type in types.dropFirst() {
            common.formIntersection(type.allHandlers)
        }
        return common.sorted { a, b in
            appName(for: a).localizedCaseInsensitiveCompare(appName(for: b)) == .orderedAscending
        }
    }

    /// Reassign selected file types using the modern async NSWorkspace API.
    /// Each call awaits the user's dialog response before proceeding to the next.
    func reassignSelectedTypes(to targetBundleID: String) {
        let utis = Array(selectedFileTypes).sorted()
        guard !utis.isEmpty else { return }

        isReassigning = true
        reassignProgress = 0
        reassignTotal = utis.count
        reassignErrors = []

        // Start auto-confirm if enabled
        if autoConfirmEnabled {
            autoConfirm.start()
        }

        Task {
            for uti in utis {
                do {
                    try await service.setDefaultHandler(for: uti, bundleID: targetBundleID)
                } catch {
                    reassignErrors.append("\(uti): \(error.localizedDescription)")
                }
                reassignProgress += 1
            }

            autoConfirm.stop()
            isReassigning = false

            // Wait briefly for LaunchServices to commit, then refresh
            try? await Task.sleep(for: .milliseconds(500))
            refreshHandlers()
        }
    }

    // MARK: - File Monitoring

    private func startMonitoring() {
        monitor?.stop()
        monitor = LaunchServicesMonitor { [weak self] in
            // Debounce: wait 1s after last change before refreshing
            self?.refreshDebounce?.cancel()
            self?.refreshDebounce = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.refreshHandlers()
            }
        }
        monitor?.start()
    }

    // MARK: - Auto-Confirm

    private func updateAutoConfirm() {
        if !autoConfirmEnabled {
            autoConfirm.stop()
        }
    }
}
