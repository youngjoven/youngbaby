import SwiftUI
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    var advisorResponse: AdvisorResponse?
    var showAdvisorCard = false

    func syncProfile(_ profile: UserProfile) {
        Task {
            try? await APIService.shared.uploadProfile(
                babyName: profile.babyName,
                babyBirthDate: profile.babyBirthDate,
                motherName: profile.motherName
            )
        }
    }

    func saveFeedingRecord(
        amountMl: Int,
        userId: String,
        profile: UserProfile?,
        modelContext: ModelContext
    ) {
        guard amountMl > 0 else { return }
        let record = FeedingRecord(userId: userId, amountMl: amountMl)
        modelContext.insert(record)

        guard let profile else { return }
        let nextTime = AgeCalculatorService.nextFeedingTime(
            lastFeedingTime: record.feedingTime,
            ageMonths: profile.ageInMonths
        )
        Task {
            await AlarmService.scheduleAlarm(
                nextFeedingTime: nextTime,
                cognitoUserId: profile.cognitoUserId
            )
            try? await APIService.shared.uploadFeeding(
                feedingTime: record.feedingTime,
                amountMl: amountMl
            )
            if let advice = try? await APIService.shared.fetchAdvice() {
                advisorResponse = advice
                withAnimation { showAdvisorCard = true }
            }
        }
    }

    func saveBowelRecord(
        time: Date,
        condition: BowelCondition,
        userId: String,
        modelContext: ModelContext
    ) {
        let record = BowelRecord(userId: userId, bowelTime: time, condition: condition)
        modelContext.insert(record)
        Task {
            try? await APIService.shared.uploadBowel(
                bowelTime: time,
                condition: condition.rawValue
            )
        }
    }
}
