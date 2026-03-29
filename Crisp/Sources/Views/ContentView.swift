import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .capture

    enum Tab {
        case capture
        case library
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem {
                    Label("Capture", systemImage: "mic.fill")
                }
                .tag(Tab.capture)

            CaptureListView()
                .tabItem {
                    Label("Library", systemImage: "list.bullet")
                }
                .tag(Tab.library)
        }
        .tint(DesignTokens.accent)
        .preferredColorScheme(.dark)
    }
}
