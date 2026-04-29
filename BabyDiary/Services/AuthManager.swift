import Foundation

/// 앱 전체 로그인 상태 관리
@MainActor
class AuthManager: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userId = ""
    @Published private(set) var isInitializing = true
    private(set) var accessToken = ""

    private static let refreshTokenKey = "cognitoRefreshToken"
    private static let autoLoginEnabledKey = "autoLoginEnabled"
    private var hasAttemptedAutoLogin = false

    static var isAutoLoginEnabled: Bool {
        UserDefaults.standard.object(forKey: autoLoginEnabledKey) as? Bool ?? true
    }

    /// 앱 시작 시 한 번 호출 — Keychain의 refreshToken으로 자동 로그인 시도
    func tryAutoLogin() async {
        guard !hasAttemptedAutoLogin else { return }
        hasAttemptedAutoLogin = true
        defer { isInitializing = false }

        guard Self.isAutoLoginEnabled,
              let refreshToken = KeychainHelper.read(forKey: Self.refreshTokenKey) else { return }

        do {
            let tokens = try await CognitoService.refresh(refreshToken: refreshToken)
            await APIService.shared.setIdToken(tokens.idToken)
            self.accessToken = tokens.accessToken
            self.userId = Self.extractUserId(from: tokens.idToken)
            self.isLoggedIn = true
        } catch {
            // 자동 로그인 실패 — 토큰은 그대로 두고 사용자가 수동 로그인하도록 함
            // (네트워크 일시 오류와 만료/무효를 구분하기 어려우므로 보수적으로 보존)
            print("[AutoLogin] failed: \(error)")
        }
    }

    func login(idToken: String, accessToken: String, refreshToken: String) async {
        await APIService.shared.setIdToken(idToken)
        self.accessToken = accessToken
        self.userId = Self.extractUserId(from: idToken)
        if Self.isAutoLoginEnabled {
            KeychainHelper.save(refreshToken, forKey: Self.refreshTokenKey)
        } else {
            KeychainHelper.delete(forKey: Self.refreshTokenKey)
        }
        isLoggedIn = true
    }

    func logout() {
        Task { await APIService.shared.setIdToken("") }
        KeychainHelper.delete(forKey: Self.refreshTokenKey)
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
