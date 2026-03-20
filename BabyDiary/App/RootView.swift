import SwiftUI
import SwiftData

/// 로그인 → 온보딩 → 메인탭 순서로 화면 분기
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Query private var profiles: [UserProfile]

    var body: some View {
        if !authManager.isLoggedIn {
            AuthView()
        } else if profiles.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
