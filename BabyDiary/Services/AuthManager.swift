import Foundation

/// 앱 전체 로그인 상태 관리
@MainActor
class AuthManager: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userId = ""
    private(set) var accessToken = ""

    func login(idToken: String, accessToken: String) async {
        await APIService.shared.setIdToken(idToken)
        self.accessToken = accessToken
        self.userId = Self.extractUserId(from: idToken)
        isLoggedIn = true
    }

    func logout() {
        Task { await APIService.shared.setIdToken("") }
        accessToken = ""
        userId = ""
        isLoggedIn = false
    }

    /// JWT payload(Base64)에서 Cognito sub(userId) 추출
    private static func extractUserId(from idToken: String) -> String {
        let parts = idToken.components(separatedBy: ".")
        guard parts.count == 3 else { return "" }
        var base64 = parts[1]
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return "" }
        return sub
    }
}
