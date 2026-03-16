import Foundation
import UserNotifications

/// SNS/APNs 기반 수유 알람 서비스
/// 수유 기록 완료 후 Lambda → SNS → APNs 경로로 알람 발송
/// 로컬에서는 다음 수유 예정 시각을 계산하여 API로 전달
struct AlarmService {

    /// 다음 수유 알람 예약 요청 (서버로 전송)
    /// - Parameters:
    ///   - nextFeedingTime: 다음 권장 수유 시각
    ///   - cognitoUserId: Cognito 사용자 ID (다중 기기 전송 기준)
    static func scheduleAlarm(nextFeedingTime: Date, cognitoUserId: String) async {
        await APIService.shared.scheduleAlarm(
            nextFeedingTime: nextFeedingTime,
            userId: cognitoUserId
        )
    }

    /// 알람 수신을 위한 APNs 디바이스 토큰 등록
    static func registerDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        await APIService.shared.registerDeviceToken(tokenString)
    }

    /// 로컬 알림 권한 요청 (앱 최초 실행 시)
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
