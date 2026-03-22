import Foundation

/// 앱 전체 로그인 상태 관리
/// BabyDiaryApp에서 @StateObject로 생성 후 .environmentObject로 전달
@MainActor
class AuthManager: ObservableObject {
    @Published private(set) var isLoggedIn = false
    private(set) var accessToken = ""

    func login(idToken: String, accessToken: String) async {
        await APIService.shared.setIdToken(idToken)
        self.accessToken = accessToken
        isLoggedIn = true
    }

    func logout() {
        Task { await APIService.shared.setIdToken("") }
        accessToken = ""
        isLoggedIn = false
    }
}
