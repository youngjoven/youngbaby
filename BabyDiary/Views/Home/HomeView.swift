import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \FeedingRecord.feedingTime, order: .reverse) private var feedings: [FeedingRecord]
    @Query(sort: \BowelRecord.bowelTime, order: .reverse) private var bowels: [BowelRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var showFeedingInput = false
    @State private var showBowelInput = false
    @State private var advisorResponse: AdvisorResponse?
    @State private var showAdvisorCard = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 아이 정보 헤더
                        profileHeaderView

                        // 오늘 요약 카드
                        todaySummaryCard

                        // 수유·배변 기록 버튼
                        recordButtonsView

                        // 어드바이저 추천 카드 (수유 후 자동 표시)
                        if showAdvisorCard, let advice = advisorResponse {
                            AdvisorCardView(response: advice)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("아기 일기장")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFeedingInput) {
                FeedingInputModal { amountMl in
                    saveFeedingRecord(amountMl: amountMl)
                }
            }
            .sheet(isPresented: $showBowelInput) {
                BowelInputModal { time, condition in
                    saveBowelRecord(time: time, condition: condition)
                }
            }
        }
    }

    // MARK: - 서브 뷰

    private var profileHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("안녕하세요, \(profile?.motherName ?? "")님 👋")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(profile?.babyName ?? "아기") · \(profile?.ageInMonths ?? 0)개월")
                    .font(.title2.bold())
            }
            Spacer()
            Text("🍼")
                .font(.system(size: 40))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var todaySummaryCard: some View {
        VStack(spacing: 12) {
            Text("오늘 요약")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                SummaryTile(
                    emoji: "🍼",
                    title: "수유",
                    value: "\(FeedingService.todayCount(records: feedings))회",
                    subtitle: "총 \(FeedingService.dailyTotal(records: feedings))ml"
                )
                SummaryTile(
                    emoji: "💩",
                    title: "배변",
                    value: "\(todayBowelCount)회",
                    subtitle: lastBowelCondition
                )
                SummaryTile(
                    emoji: "⏰",
                    title: "다음 수유",
                    value: nextFeedingTimeText,
                    subtitle: "권장 시각"
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var recordButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: { showFeedingInput = true }) {
                Label("수유 기록하기", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color("PastelPink")))
            }

            Button(action: { showBowelInput = true }) {
                Label("배변 기록하기", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color("PastelMint")))
            }
        }
    }

    // MARK: - 계산 프로퍼티

    private var todayBowelCount: Int {
        bowels.filter { Calendar.current.isDateInToday($0.bowelTime) }.count
    }

    private var lastBowelCondition: String {
        bowels.first.map { $0.bowelCondition.displayName } ?? "-"
    }

    private var nextFeedingTimeText: String {
        guard let last = feedings.first, let ageMonths = profile?.ageInMonths else { return "-" }
        let next = AgeCalculatorService.nextFeedingTime(lastFeedingTime: last.feedingTime, ageMonths: ageMonths)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: next)
    }

    // MARK: - 기록 저장

    private func saveFeedingRecord(amountMl: Int) {
        guard amountMl > 0 else { return }
        let record = FeedingRecord(amountMl: amountMl)
        modelContext.insert(record)

        // 알람 예약 + 어드바이저 추천 요청
        if let profile = profile {
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
                    await MainActor.run {
                        advisorResponse = advice
                        withAnimation { showAdvisorCard = true }
                    }
                }
            }
        }
    }

    private func saveBowelRecord(time: Date, condition: BowelCondition) {
        let record = BowelRecord(bowelTime: time, condition: condition)
        modelContext.insert(record)
        Task {
            try? await APIService.shared.uploadBowel(
                bowelTime: time,
                condition: condition.rawValue
            )
        }
    }
}

// MARK: - 요약 타일 컴포넌트

struct SummaryTile: View {
    let emoji: String
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline.bold())
            Text(subtitle).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("PastelBackground")))
    }
}
