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

    // MARK: - 로그인 → IdToken 반환
    static func signIn(email: String, password: String) async throws -> String {
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": ["USERNAME": email, "PASSWORD": password]
        ]
        let json = try await request(target: "AWSCognitoIdentityProviderService.InitiateAuth", body: body)
        guard
            let result = json["AuthenticationResult"] as? [String: Any],
            let idToken = result["IdToken"] as? String
        else {
            throw CognitoError.authFailed("로그인에 실패했습니다. 이메일과 비밀번호를 확인하세요.")
        }
        return idToken
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
