import Foundation
import SwiftData

@Model
final class UserProfile {
    var babyName: String
    var babyBirthDate: Date
    var motherName: String
    var cognitoUserId: String

    init(babyName: String, babyBirthDate: Date, motherName: String, cognitoUserId: String = "") {
        self.babyName = babyName
        self.babyBirthDate = babyBirthDate
        self.motherName = motherName
        self.cognitoUserId = cognitoUserId
    }

    /// 생년월일 기반 월령 자동 계산
    var ageInMonths: Int {
        let components = Calendar.current.dateComponents([.month], from: babyBirthDate, to: Date())
        return max(0, components.month ?? 0)
    }
}
