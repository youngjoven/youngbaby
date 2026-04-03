import Foundation
import SwiftData

@Model
final class FeedingRecord {
    var userId: String = ""
    var feedingTime: Date
    var amountMl: Int
    var syncedAt: Date?

    init(userId: String, feedingTime: Date = Date(), amountMl: Int) {
        self.userId = userId
        self.feedingTime = feedingTime
        self.amountMl = amountMl
    }
}
