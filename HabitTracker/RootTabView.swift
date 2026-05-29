import SwiftUI
import UIKit

enum HTTab: Hashable {
    case habits, jardim, stats, settings
}

struct RootTabView: View {
    @State private var tab: HTTab = .habits
    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85

    var body: some View {
        TabView(selection: $tab) {

            HomeView(selectedTab: $tab)
                .tag(HTTab.habits)
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Hoje")
                }

            GardenScreen()
                .tag(HTTab.jardim)
                .tabItem {
                    Image(systemName: "camera.macro")
                    Text("Jardim")
                }

            StatsView()
                .tag(HTTab.stats)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Estatísticas")
                }

            SettingsView()
                .tag(HTTab.settings)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Ajustes")
                }
        }
        .toolbarBackground(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .onAppear {
            normalizeInterfaceScale()
            HTAppearance.configureTabBarTransparent()
            configureTabBarTypography()
        }
        .onChange(of: uiScale) { _, _ in
            normalizeInterfaceScale()
            configureTabBarTypography()
        }
    }

    private func configureTabBarTypography() {
        let scale = CGFloat(min(max(uiScale, 0.75), 1.0))
        let normalFont = UIFont.systemFont(ofSize: 10 * scale, weight: .semibold)
        let selectedFont = UIFont.systemFont(ofSize: 10 * scale, weight: .bold)

        let appearance = UITabBarItemAppearance()
        appearance.normal.titleTextAttributes = [.font: normalFont]
        appearance.selected.titleTextAttributes = [.font: selectedFont]

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = .clear
        tabBarAppearance.shadowColor = .clear
        tabBarAppearance.stackedLayoutAppearance = appearance
        tabBarAppearance.inlineLayoutAppearance = appearance
        tabBarAppearance.compactInlineLayoutAppearance = appearance

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    private func normalizeInterfaceScale() {
        let normalized = HTInterfaceScaleLevel.nearest(to: uiScale).rawValue
        if abs(uiScale - normalized) > 0.001 {
            uiScale = normalized
        }
    }
}
