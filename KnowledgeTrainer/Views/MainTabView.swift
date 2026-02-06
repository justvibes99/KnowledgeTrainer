import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

            ProfileDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Progress")
                }
                .tag(1)

            SettingsTabView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(.brutalBlack)
        .onAppear {
            applyAppearanceMode()
            ensureScholarProfile()
        }
    }

    private func ensureScholarProfile() {
        let descriptor = FetchDescriptor<ScholarProfile>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        if count == 0 {
            modelContext.insert(ScholarProfile())
            try? modelContext.save()
        }
    }
}
