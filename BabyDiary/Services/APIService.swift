import Foundation

/// AWS API Gateway 연동 서비스
/// 실제 API URL 및 Cognito 설정은 Config.xcconfig에서 주입 (보안상 코드에 직접 기재 금지)
actor APIService {
    static let shared = APIService()

    private var baseURL: String { AppConfig.apiBaseURL }

    private var idToken: String = ""

    // MARK: - Auth

    func setIdToken(_ token: String) {
        self.idToken = token
    }

    private func authorizedRequest(path: String, method: String = "GET") -> URLRequest? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - Feeding Records

    func uploadFeeding(feedingTime: Date, amountMl: Int) async throws {
        guard var request = authorizedRequest(path: "/feedings", method: "POST") else { return }
        let body: [String: Any] = [
            "feedingTime": ISO8601DateFormatter().string(from: feedingTime),
            "amountMl": amountMl
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    func fetchFeedings(from: Date, to: Date) async throws -> [[String: Any]] {
        guard var request = authorizedRequest(path: "/feedings") else { return [] }
        let formatter = ISO8601DateFormatter()
        let urlString = baseURL + "/feedings?from=\(formatter.string(from: from))&to=\(formatter.string(from: to))"
        request.url = URL(string: urlString)
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    // MARK: - Bowel Records

    func uploadBowel(bowelTime: Date, condition: String) async throws {
        guard var request = authorizedRequest(path: "/bowels", method: "POST") else { return }
        let body: [String: Any] = [
            "bowelTime": ISO8601DateFormatter().string(from: bowelTime),
            "condition": condition
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Profile

    func uploadProfile(babyName: String, babyBirthDate: Date, motherName: String) async throws {
        guard var request = authorizedRequest(path: "/profile", method: "PUT") else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let body: [String: Any] = [
            "babyName": babyName,
            "babyBirthDate": formatter.string(from: babyBirthDate),
            "motherName": motherName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Advisor

    func fetchAdvice() async throws -> AdvisorResponse? {
        guard var request = authorizedRequest(path: "/advisor/advice", method: "POST") else { return nil }
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AdvisorResponse.self, from: data)
    }

    // MARK: - Insights

    func fetchInsights() async throws -> [InsightItem] {
        guard let request = authorizedRequest(path: "/insights") else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try? JSONDecoder().decode([InsightItem].self, from: data)) ?? []
    }

    // MARK: - Alarm

    func scheduleAlarm(nextFeedingTime: Date, userId: String) async {
        guard var request = authorizedRequest(path: "/alarm/schedule", method: "POST") else { return }
        let body: [String: Any] = [
            "nextFeedingTime": ISO8601DateFormatter().string(from: nextFeedingTime),
            "userId": userId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    func registerDeviceToken(_ token: String) async {
        guard var request = authorizedRequest(path: "/device/token", method: "POST") else { return }
        let body: [String: Any] = ["deviceToken": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Account

    func deleteUserAccount() async throws {
        guard let request = authorizedRequest(path: "/account", method: "DELETE") else { return }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            let message = (json["message"] as? String) ?? "계정 삭제에 실패했습니다."
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}

// MARK: - Response Models

struct AdvisorResponse: Codable {
    let nextFeedingAdvice: String
    let amountAdvice: String
    let overallOpinion: String
    let disclaimer: String
}

struct InsightItem: Codable, Identifiable {
    let id: String
    let insightType: String
    let content: String
    let generatedAt: String
}
