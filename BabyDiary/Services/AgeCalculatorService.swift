import Foundation

/// 월령별 권장 수유 기준 (대한소아과학회·WHO 공개 가이드라인 참고용)
struct AgeRecommendation {
    let minIntervalHours: Double
    let maxIntervalHours: Double
    let minAmountMl: Int
    let maxAmountMl: Int
    let dailyMinAmountMl: Int
    let dailyMaxAmountMl: Int
    let feedingsPerDayMin: Int
    let feedingsPerDayMax: Int

    var midIntervalHours: Double {
        (minIntervalHours + maxIntervalHours) / 2
    }

    var displayInterval: String {
        "\(Int(minIntervalHours))~\(Int(maxIntervalHours))시간"
    }

    var displayAmount: String {
        "\(minAmountMl)~\(maxAmountMl)ml"
    }

    var disclaimer: String {
        "권장 수유 간격 및 분유량은 대한소아과학회·WHO 가이드라인을 참고한 것으로, 의료적 진단을 대체하지 않습니다."
    }
}

struct AgeCalculatorService {

    /// 생년월일로부터 현재 월령(개월 수) 계산
    static func ageInMonths(from birthDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.month], from: birthDate, to: Date())
        return max(0, components.month ?? 0)
    }

    /// 월령에 맞는 권장 수유 기준 반환
    static func recommendation(forAgeMonths age: Int) -> AgeRecommendation {
        switch age {
        case 0..<1:
            return AgeRecommendation(
                minIntervalHours: 2, maxIntervalHours: 3,
                minAmountMl: 60, maxAmountMl: 90,
                dailyMinAmountMl: 500, dailyMaxAmountMl: 700,
                feedingsPerDayMin: 8, feedingsPerDayMax: 12
            )
        case 1..<3:
            return AgeRecommendation(
                minIntervalHours: 3, maxIntervalHours: 4,
                minAmountMl: 90, maxAmountMl: 120,
                dailyMinAmountMl: 700, dailyMaxAmountMl: 900,
                feedingsPerDayMin: 6, feedingsPerDayMax: 8
            )
        case 3..<6:
            return AgeRecommendation(
                minIntervalHours: 3, maxIntervalHours: 4,
                minAmountMl: 120, maxAmountMl: 180,
                dailyMinAmountMl: 800, dailyMaxAmountMl: 1000,
                feedingsPerDayMin: 5, feedingsPerDayMax: 6
            )
        default: // 6~12개월
            return AgeRecommendation(
                minIntervalHours: 4, maxIntervalHours: 5,
                minAmountMl: 180, maxAmountMl: 240,
                dailyMinAmountMl: 600, dailyMaxAmountMl: 900,
                feedingsPerDayMin: 3, feedingsPerDayMax: 5
            )
        }
    }

    /// 마지막 수유 시간 + 권장 간격 중간값 = 다음 권장 수유 시각
    static func nextFeedingTime(lastFeedingTime: Date, ageMonths: Int) -> Date {
        let rec = recommendation(forAgeMonths: ageMonths)
        let interval = rec.midIntervalHours * 3600
        return lastFeedingTime.addingTimeInterval(interval)
    }
}
