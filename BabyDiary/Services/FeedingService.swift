import Foundation
import SwiftData

struct FeedingService {

    /// 평균 수유 간격 계산 (시간 단위)
    static func averageInterval(records: [FeedingRecord]) -> Double? {
        let sorted = records.sorted { $0.feedingTime < $1.feedingTime }
        guard sorted.count >= 2 else { return nil }
        var intervals: [Double] = []
        for i in 1..<sorted.count {
            let diff = sorted[i].feedingTime.timeIntervalSince(sorted[i - 1].feedingTime)
            intervals.append(diff / 3600)
        }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    /// 1회 평균 분유량 계산
    static func averageAmount(records: [FeedingRecord]) -> Double? {
        guard !records.isEmpty else { return nil }
        let total = records.reduce(0) { $0 + $1.amountMl }
        return Double(total) / Double(records.count)
    }

    /// 하루 총 분유량 계산
    static func dailyTotal(records: [FeedingRecord], date: Date = Date()) -> Int {
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.feedingTime, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amountMl }
    }

    /// 오늘 수유 횟수
    static func todayCount(records: [FeedingRecord]) -> Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.feedingTime, inSameDayAs: Date()) }.count
    }
}
