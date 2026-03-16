import SwiftUI
import SwiftData

/// 온보딩 완료 여부에 따라 메인 탭 또는 온보딩 화면 분기
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
