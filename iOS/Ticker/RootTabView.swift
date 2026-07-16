import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            MeetingListView()
                .tabItem {
                    Label("Home", systemImage: "timer")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(TKTheme.coral)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(TKTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(TickerStore())
        .environmentObject(PurchaseManager())
}
