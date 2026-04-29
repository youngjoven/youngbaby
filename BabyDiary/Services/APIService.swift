import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 요청입니다."
        case .httpError(let code, let message):
            return "서버 오류(\(code)): \(message)"
        case .decodingFailed:
            return "데이터를 처리할 수 없습니다."
        }
    }
}

/// AWS API Gateway 연동 서비스
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

    // MARK: - Common

    private func authorizedRequest(path: String, method: String = "GET", queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else { throw APIError.invalidURL }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["message"]
                ?? "요청에 실패했습니다."
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
        return data
    }

    // MARK: - Feeding Records

    func uploadFeeding(feedingTime: Date, amountMl: Int) async throws {
        var request = try authorizedRequest(path: "/feedings", method: "POST")
        let body: [String: Any] = [
            "feedingTime": isoFormatter.string(from: feedingTime),
            "amountMl": amountMl
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
    }

    func fetchFeedings(from: Date, to: Date) async throws -> [ServerFeeding] {
        let query = [
            URLQueryItem(name: "from", value: isoFormatter.string(from: from)),
            URLQueryItem(name: "to", value: isoFormatter.string(from: to))
        ]
        let request = try authorizedRequest(path: "/feedings", queryItems: query)
        let (data, response) = try await URLSession.shared.data(for: request)
        let validated = try validateResponse(data, response)
        return (try? JSONDecoder().decode([ServerFeeding].self, from: validated)) ?? []
    }

    func deleteFeeding(feedingTime: Date) async throws {
        let id = isoFormatter.string(from: feedingTime)
        let request = try authorizedRequest(path: "/feedings/\(id)", method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
    }

    // MARK: - Bowel Records

    func uploadBowel(bowelTime: Date, condition: String) async throws {
        var request = try authorizedRequest(path: "/bowels", method: "POST")
        let body: [String: Any] = [
            "bowelTime": isoFormatter.string(from: bowelTime),
            "condition": condition
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
    }

    func fetchBowels(from: Date, to: Date) async throws -> [ServerBowel] {
        let query = [
            URLQueryItem(name: "from", value: isoFormatter.string(from: from)),
            URLQueryItem(name: "to", value: isoFormatter.string(from: to))
        ]
        let request = try authorizedRequest(path: "/bowels", queryItems: query)
        let (data, response) = try await URLSession.shared.data(for: request)
        let validated = try validateResponse(data, response)
        return (try? JSONDecoder().decode([ServerBowel].self, from: validated)) ?? []
    }

    func deleteBowel(bowelTime: Date) async throws {
        let id = isoFormatter.string(from: bowelTime)
        let request = try authorizedRequest(path: "/bowels/\(id)", method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
    }

    // MARK: - Profile

    func uploadProfile(babyName: String, babyBirthDate: Date, motherName: String) async throws {
        var request = try authorizedRequest(path: "/profile", method: "PUT")
        let body: [String: Any] = [
            "babyName": babyName,
            "babyBirthDate": dateOnlyFormatter.string(from: babyBirthDate),
            "motherName": motherName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
    }

    func fetchProfile() async throws -> ServerProfile? {
        let request = try authorizedRequest(path: "/profile")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        if http.statusCode == 404 { return nil }
        let validated = try validateResponse(data, response)
        return try? JSONDecoder().decode(ServerProfile.self, from: validated)
    }

    // MARK: - Advisor

    func fetchAdvice() async throws -> AdvisorResponse? {
        var request = try authorizedRequest(path: "/advisor/advice", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        let (data, response) = try await URLSession.shared.data(for: request)
        let validated = try validateResponse(data, response)
        return try JSONDecoder().decode(AdvisorResponse.self, from: validated)
    }

    // MARK: - Insights

    func fetchInsights() async throws -> [InsightItem] {
        let request = try authorizedRequest(path: "/insights")
        let (data, response) = try await URLSession.shared.data(for: request)
        let validated = try validateResponse(data, response)
        return (try? JSONDecoder().decode([InsightItem].self, from: validated)) ?? []
    }

    // MARK: - Alarm

    func scheduleAlarm(nextFeedingTime: Date, userId: String) async {
        guard var request = try? authorizedRequest(path: "/alarm/schedule", method: "POST") else { return }
        let body: [String: Any] = [
            "nextFeedingTime": isoFormatter.string(from: nextFeedingTime),
            "userId": userId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    func registerDeviceToken(_ token: String) async {
        guard var request = try? authorizedRequest(path: "/device/token", method: "POST") else { return }
        let body: [String: Any] = ["deviceToken": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Account

    func deleteUserAccount() async throws {
        let request = try authorizedRequest(path: "/account", method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        _ = try validateResponse(data, response)
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
