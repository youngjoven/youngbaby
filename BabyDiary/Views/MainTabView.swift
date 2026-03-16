import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            RecordView()
                .tabItem {
                    Label("기록", systemImage: "list.bullet.clipboard.fill")
                }

            AdvisorView()
                .tabItem {
                    Label("어드바이저", systemImage: "sparkles")
                }

            InsightsView()
                .tabItem {
                    Label("인사이트", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color("PastelPink"))
    }
}
