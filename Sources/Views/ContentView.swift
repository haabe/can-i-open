import SwiftUI

enum ViewMode: String, CaseIterable {
    case fileTypes = "File Types"
    case apps = "Apps"
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var viewMode: ViewMode = .fileTypes

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area
            HStack {
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                if viewMode == .fileTypes && !appState.selectedFileTypes.isEmpty {
                    Text("\(appState.selectedFileTypes.count) selected")
                        .foregroundStyle(.secondary)
                    ReassignButton()
                }

                AutoConfirmToggle()

                SearchField(text: $appState.searchText)
                    .frame(width: 250)
            }
            .padding()

            Divider()

            // Reassignment progress banner
            if appState.isReassigning {
                ReassignProgressBanner()
                Divider()
            }

            // Main content
            if appState.isLoading {
                VStack {
                    ProgressView("Scanning installed apps and file types...")
                        .padding()
                    Spacer()
                }
            } else {
                switch viewMode {
                case .fileTypes:
                    FileTypeListView()
                case .apps:
                    AppListView()
                }
            }
        }
    }
}

struct AutoConfirmToggle: View {
    @EnvironmentObject var appState: AppState
    @State private var showPermissionAlert = false

    var body: some View {
        Button {
            if appState.autoConfirmEnabled {
                appState.autoConfirmEnabled = false
            } else if DialogAutoConfirm.testPermission() {
                appState.autoConfirmEnabled = true
            } else {
                showPermissionAlert = true
            }
        } label: {
            Image(systemName: appState.autoConfirmEnabled ? "bolt.fill" : "bolt.slash")
                .foregroundStyle(appState.autoConfirmEnabled ? .orange : .secondary)
        }
        .help(appState.autoConfirmEnabled
              ? "Auto-confirm is ON -- click to turn off"
              : "Auto-confirm is OFF -- click to enable")
        .alert("Accessibility Permission Required", isPresented: $showPermissionAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add \"Can I Open\" to System Settings > Privacy & Security > Accessibility, then try again.")
        }
    }
}

struct ReassignProgressBanner: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            ProgressView(
                value: Double(appState.reassignProgress),
                total: Double(max(appState.reassignTotal, 1))
            )
            .frame(width: 120)

            if appState.autoConfirmEnabled {
                Label("Auto-confirming... \(appState.reassignProgress)/\(appState.reassignTotal)",
                      systemImage: "bolt.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else {
                Text("Confirm each dialog... \(appState.reassignProgress)/\(appState.reassignTotal)")
                    .font(.callout)
            }

            if !appState.reassignErrors.isEmpty {
                Label("\(appState.reassignErrors.count) failed", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.06))
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search file types or apps...", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.quaternary)
        .cornerRadius(8)
    }
}
