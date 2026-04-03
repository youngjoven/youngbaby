import Foundation

/// AWS API Gateway 연동 서비스
/// 실제 API URL 및 Cognito 설정은 Config.xcconfig에서 주입 (보안상 코드에 직접 기재 금지)
actor APIService {
    static let shared = APIService()

    private var baseURL: String { AppConfig.apiBaseURL }

    private var idToken: String = ""

    private let isoFormatter = ISO8601DateFormatter()

    private let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Auth

    func setIdToken(_ token: String) {
        self.idToken = token
    }

    private func authorizedRequest(path: String, method: String = "GET", queryItems: [URLQueryItem]? = nil) -> URLRequest? {
        guard var components = URLComponents(string: baseURL + path) else { return nil }
        components.queryItems = queryItems
        guard let url = components.url else { return nil }
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
            "feedingTime": isoFormatter.string(from: feedingTime),
            "amountMl": amountMl
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    func fetchFeedings(from: Date, to: Date) async throws -> [ServerFeeding] {
        let query = [
            URLQueryItem(name: "from", value: isoFormatter.string(from: from)),
            URLQueryItem(name: "to", value: isoFormatter.string(from: to))
        ]
        guard let request = authorizedRequest(path: "/feedings", queryItems: query) else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try? JSONDecoder().decode([ServerFeeding].self, from: data)) ?? []
    }

    func deleteFeeding(feedingTime: Date) async throws {
        let id = isoFormatter.string(from: feedingTime)
        guard let request = authorizedRequest(path: "/feedings/\(id)", method: "DELETE") else { return }
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Bowel Records

    func uploadBowel(bowelTime: Date, condition: String) async throws {
        guard var request = authorizedRequest(path: "/bowels", method: "POST") else { return }
        let body: [String: Any] = [
            "bowelTime": isoFormatter.string(from: bowelTime),
            "condition": condition
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Profile

    func uploadProfile(babyName: String, babyBirthDate: Date, motherName: String) async throws {
        guard var request = authorizedRequest(path: "/profile", method: "PUT") else { return }
        let body: [String: Any] = [
            "babyName": babyName,
            "babyBirthDate": dateOnlyFormatter.string(from: babyBirthDate),
            "motherName": motherName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    func fetchProfile() async throws -> ServerProfile? {
        guard let request = authorizedRequest(path: "/profile") else { return nil }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(ServerProfile.self, from: data)
    }

    func fetchBowels(from: Date, to: Date) async throws -> [ServerBowel] {
        let query = [
            URLQueryItem(name: "from", value: isoFormatter.string(from: from)),
            URLQueryItem(name: "to", value: isoFormatter.string(from: to))
        ]
        guard let request = authorizedRequest(path: "/bowels", queryItems: query) else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try? JSONDecoder().decode([ServerBowel].self, from: data)) ?? []
    }

    func deleteBowel(bowelTime: Date) async throws {
        let id = isoFormatter.string(from: bowelTime)
        guard let request = authorizedRequest(path: "/bowels/\(id)", method: "DELETE") else { return }
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
            "nextFeedingTime": isoFormatter.string(from: nextFeedingTime),
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

struct ServerProfile: Codable, Sendable {
    let babyName: String
    let babyBirthDate: String
    let motherName: String?
}

struct ServerFeeding: Codable, Sendable {
    let feedingTime: String
    let amountMl: Int
}

struct ServerBowel: Codable, Sendable {
    let bowelTime: String
    let condition: String
}

struct AdvisorResponse: Codable, Sendable {
    let nextFeedingAdvice: String
    let amountAdvice: String
    let overallOpinion: String
    let disclaimer: String
}

struct InsightItem: Codable, Identifiable, Sendable {
    let id: String
    let insightType: String
    let content: String
    let generatedAt: String
}
