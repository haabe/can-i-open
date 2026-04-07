import SwiftUI

@main
struct CanIOpenApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    appState.loadData()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 650)
    }
}
