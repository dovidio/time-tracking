import SwiftUI

struct RootView: View {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView(model: model)
                .tabItem { Label("Today", systemImage: "clock") }

            HistoryView(model: model)
                .tabItem { Label("History", systemImage: "calendar") }

            SettingsView(model: model)
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(.blue)
        .task {
            while !Task.isCancelled {
                model.now = .now
                try? await Task.sleep(nanoseconds: 20 * 1_000_000_000)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.now = .now
                model.reload()
            }
        }
    }
}
