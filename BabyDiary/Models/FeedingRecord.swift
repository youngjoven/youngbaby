import Foundation
import SwiftData

@Model
final class FeedingRecord {
    var feedingTime: Date
    var amountMl: Int
    var syncedAt: Date?

    init(feedingTime: Date = Date(), amountMl: Int) {
        self.feedingTime = feedingTime
        self.amountMl = amountMl
    }
}
