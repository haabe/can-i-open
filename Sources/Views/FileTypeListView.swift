import SwiftUI

struct FileTypeListView: View {
    @EnvironmentObject var appState: AppState
    @State private var sortOrder = [KeyPathComparator(\FileTypeInfo.displayName)]

    var sortedFileTypes: [FileTypeInfo] {
        appState.filteredFileTypes.sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortedFileTypes, selection: $appState.selectedFileTypes, sortOrder: $sortOrder) {
            TableColumn("Extension", value: \.displayName) { fileType in
                Text(fileType.displayName)
                    .fontWeight(.medium)
            }
            .width(min: 80, ideal: 120)

            TableColumn("Description", value: \.description) { fileType in
                Text(fileType.description)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 160)

            TableColumn("Default Editor", value: \.defaultEditorName) { fileType in
                AppLabel(
                    name: fileType.defaultEditorName,
                    icon: appState.appIcon(for: fileType.defaultEditor)
                )
            }
            .width(min: 120, ideal: 180)

            TableColumn("Default Viewer", value: \.defaultViewerName) { fileType in
                AppLabel(
                    name: fileType.defaultViewerName,
                    icon: appState.appIcon(for: fileType.defaultViewer)
                )
            }
            .width(min: 120, ideal: 180)

            TableColumn("Handlers", value: \.handlerCount) { fileType in
                Text("\(fileType.handlerCount)")
                    .foregroundStyle(.secondary)
            }
            .width(50)

            TableColumn("UTI", value: \.id) { fileType in
                Text(fileType.id)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .width(min: 120, ideal: 200)
        }
        .contextMenu(forSelectionType: String.self) { selection in
            if !selection.isEmpty {
                ContextMenuContent(selectedUTIs: selection)
            }
        } primaryAction: { _ in }
    }
}

struct ContextMenuContent: View {
    let selectedUTIs: Set<String>
    @EnvironmentObject var appState: AppState

    var body: some View {
        Text("\(selectedUTIs.count) file type(s) selected")
            .foregroundStyle(.secondary)
        Divider()

        let handlers = appState.commonHandlers(for: selectedUTIs)

        if handlers.isEmpty {
            Text("No common handlers")
                .foregroundStyle(.secondary)
        } else {
            Menu("Set Editor to...") {
                ForEach(handlers, id: \.self) { bundleID in
                    Button(appState.appName(for: bundleID)) {
                        appState.selectedFileTypes = selectedUTIs
                        appState.reassignSelectedTypes(to: bundleID)
                    }
                }
            }
            Menu("Set Viewer to...") {
                ForEach(handlers, id: \.self) { bundleID in
                    Button(appState.appName(for: bundleID)) {
                        appState.selectedFileTypes = selectedUTIs
                        appState.reassignSelectedTypes(to: bundleID)
                    }
                }
            }
        }
    }
}
