import Foundation
import SwiftData

enum BowelCondition: String, Codable, CaseIterable {
    case hard   = "hard"
    case normal = "normal"
    case soft   = "soft"

    var displayName: String {
        switch self {
        case .hard:   return "단단함"
        case .normal: return "정상"
        case .soft:   return "묽음"
        }
    }

    var description: String {
        switch self {
        case .hard:   return "변이 굳어 있음"
        case .normal: return "너무 단단하지도 묽지도 않음"
        case .soft:   return "물기가 많음"
        }
    }

    var emoji: String {
        switch self {
        case .hard:   return "🟤"
        case .normal: return "🟢"
        case .soft:   return "🟡"
        }
    }
}

@Model
final class BowelRecord {
    var userId: String = ""
    var bowelTime: Date
    var condition: String
    var syncedAt: Date?

    var bowelCondition: BowelCondition {
        get { BowelCondition(rawValue: condition) ?? .normal }
        set { condition = newValue.rawValue }
    }

    init(userId: String, bowelTime: Date, condition: BowelCondition) {
        self.userId = userId
        self.bowelTime = bowelTime
        self.condition = condition.rawValue
    }
}
