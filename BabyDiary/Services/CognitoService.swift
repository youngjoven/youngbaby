import Foundation

// MARK: - 에러 타입

enum CognitoError: LocalizedError {
    case authFailed(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): return msg
        }
    }
}

// MARK: - Cognito 인증 서비스
// AWS Cognito Identity Provider REST API를 직접 호출 (SDK 불필요)

enum CognitoService {

    // MARK: - 회원가입
    static func signUp(email: String, password: String) async throws {
        let body: [String: Any] = [
            "ClientId": AppConfig.cognitoClientId,
            "Username": email,
            "Password": password,
            "UserAttributes": [["Name": "email", "Value": email]]
        ]
        try await request(target: "AWSCognitoIdentityProviderService.SignUp", body: body)
    }

    // MARK: - 이메일 인증 코드 확인
    static func confirmSignUp(email: String, code: String) async throws {
        let body: [String: Any] = [
            "ClientId": AppConfig.cognitoClientId,
            "Username": email,
            "ConfirmationCode": code
        ]
        try await request(target: "AWSCognitoIdentityProviderService.ConfirmSignUp", body: body)
    }

    // MARK: - 로그인 → (IdToken, AccessToken, RefreshToken) 반환
    static func signIn(email: String, password: String) async throws -> (idToken: String, accessToken: String, refreshToken: String) {
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": ["USERNAME": email, "PASSWORD": password]
        ]
        let json = try await request(target: "AWSCognitoIdentityProviderService.InitiateAuth", body: body)
        guard
            let result = json["AuthenticationResult"] as? [String: Any],
            let idToken = result["IdToken"] as? String,
            let accessToken = result["AccessToken"] as? String,
            let refreshToken = result["RefreshToken"] as? String
        else {
            throw CognitoError.authFailed("로그인에 실패했습니다. 이메일과 비밀번호를 확인하세요.")
        }
        return (idToken: idToken, accessToken: accessToken, refreshToken: refreshToken)
    }

    // MARK: - 자동 로그인용 토큰 갱신 (RefreshToken은 응답에 포함되지 않음, 기존 값 재사용)
    static func refresh(refreshToken: String) async throws -> (idToken: String, accessToken: String) {
        let body: [String: Any] = [
            "AuthFlow": "REFRESH_TOKEN_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": ["REFRESH_TOKEN": refreshToken]
        ]
        let json = try await request(target: "AWSCognitoIdentityProviderService.InitiateAuth", body: body)
        guard
            let result = json["AuthenticationResult"] as? [String: Any],
            let idToken = result["IdToken"] as? String,
            let accessToken = result["AccessToken"] as? String
        else {
            throw CognitoError.authFailed("자동 로그인에 실패했습니다.")
        }
        return (idToken: idToken, accessToken: accessToken)
    }

    // MARK: - 계정 삭제 (AccessToken 필요)
    static func deleteUser(accessToken: String) async throws {
        let body: [String: Any] = ["AccessToken": accessToken]
        try await request(target: "AWSCognitoIdentityProviderService.DeleteUser", body: body)
    }

    // MARK: - 공통 HTTP 요청
    @discardableResult
    private static func request(target: String, body: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: AppConfig.cognitoEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        req.setValue(target, forHTTPHeaderField: "X-Amz-Target")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let message = (json["message"] as? String)
                ?? (json["Message"] as? String)
                ?? "알 수 없는 오류가 발생했습니다."
            throw CognitoError.authFailed(message)
        }
        return json
    }
}
