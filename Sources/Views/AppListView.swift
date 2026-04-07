import SwiftUI

struct AppListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppID: String?

    var filteredApps: [AppInfo] {
        let apps = appState.appsByClaimCount
        guard !appState.searchText.isEmpty else { return apps }
        let query = appState.searchText.lowercased()
        return apps.filter { app in
            app.name.lowercased().contains(query)
            || app.id.lowercased().contains(query)
            || app.claimedTypes.contains { claim in
                claim.extensions.contains { $0.lowercased().contains(query) }
                || claim.name.lowercased().contains(query)
            }
        }
    }

    var selectedApp: AppInfo? {
        guard let id = selectedAppID else { return nil }
        return appState.installedApps.first { $0.id == id }
    }

    var body: some View {
        HSplitView {
            // Sidebar: app list
            VStack(spacing: 0) {
                List(filteredApps, selection: $selectedAppID) { app in
                    HStack(spacing: 8) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .fontWeight(.medium)
                            Text("\(app.claimedTypes.count) types claimed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    .tag(app.id)
                }
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 350)

            // Detail: claimed types
            if let app = selectedApp {
                AppDetailView(app: app)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select an app to see its claimed file types")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// A claimed type row for the detail table.
struct ClaimedTypeRow: Identifiable {
    let id: String  // UTI
    let extensions: String
    let typeName: String
    let isDefaultEditor: Bool
    let isDefaultViewer: Bool
    let currentEditorName: String
    let currentViewerName: String
}

struct AppDetailView: View {
    let app: AppInfo
    @EnvironmentObject var appState: AppState
    @State private var sortOrder = [KeyPathComparator(\ClaimedTypeRow.extensions)]

    var claimedTypeRows: [ClaimedTypeRow] {
        app.claimedTypes.map { claim in
            let fileType = appState.fileTypes.first { $0.id == claim.uti }
            return ClaimedTypeRow(
                id: claim.uti,
                extensions: claim.extensions.map { ".\($0)" }.joined(separator: ", "),
                typeName: claim.name,
                isDefaultEditor: fileType?.defaultEditor == app.id,
                isDefaultViewer: fileType?.defaultViewer == app.id,
                currentEditorName: fileType?.defaultEditorName ?? "None",
                currentViewerName: fileType?.defaultViewerName ?? "None"
            )
        }
        .sorted(using: sortOrder)
    }

    var defaultEditorCount: Int {
        claimedTypeRows.filter(\.isDefaultEditor).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App header
            HStack(spacing: 12) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(app.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(app.claimedTypes.count) file types claimed, \(defaultEditorCount) as default editor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Claimed types table
            Table(claimedTypeRows, sortOrder: $sortOrder) {
                TableColumn("Extension", value: \.extensions) { item in
                    Text(item.extensions)
                        .fontWeight(.medium)
                }
                .width(min: 80, ideal: 120)

                TableColumn("Type Name", value: \.typeName) { item in
                    Text(item.typeName)
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 160)

                TableColumn("Default Editor", value: \.currentEditorName) { item in
                    if item.isDefaultEditor {
                        Label("This app", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text(item.currentEditorName)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 100, ideal: 140)

                TableColumn("Default Viewer", value: \.currentViewerName) { item in
                    if item.isDefaultViewer {
                        Label("This app", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text(item.currentViewerName)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 100, ideal: 140)

                TableColumn("UTI", value: \.id) { item in
                    Text(item.id)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .width(min: 120, ideal: 200)
            }
        }
    }
}
