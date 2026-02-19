import SwiftUI

enum HTTab: Hashable {
    case habits, jardim, stats
}

struct RootTabView: View {
    @State private var tab: HTTab = .habits

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectedTab: $tab)
                .tag(HTTab.habits)
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Hábitos")
                }

            JardimView()
                .tag(HTTab.jardim)
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Jardim")
                }

            StatsView()
                .tag(HTTab.stats)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
            GardenScreen()
                .tabItem {
                    Label("Jardim", systemImage: "leaf")
                }
        }
    }
}
