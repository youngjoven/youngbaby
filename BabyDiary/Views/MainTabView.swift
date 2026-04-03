import SwiftUI

struct MainTabView: View {
    let userId: String
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userId: userId, selectedTab: $selectedTab)
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(0)

            RecordView(userId: userId)
                .tabItem { Label("기록", systemImage: "list.bullet.clipboard.fill") }
                .tag(1)

            AdvisorView()
                .tabItem { Label("어드바이저", systemImage: "sparkles") }
                .tag(2)

            InsightsView()
                .tabItem { Label("인사이트", systemImage: "chart.bar.fill") }
                .tag(3)

            SettingsView(userId: userId)
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.appPink)
    }
}
