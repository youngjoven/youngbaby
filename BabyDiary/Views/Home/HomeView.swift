import SwiftUI
import SwiftData

struct HomeView: View {
    private let userId: String
    @Binding var selectedTab: Int

    @Query private var profiles: [UserProfile]
    @Query private var feedings: [FeedingRecord]
    @Query private var bowels: [BowelRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = HomeViewModel()
    @State private var showFeedingInput = false
    @State private var showBowelInput = false

    init(userId: String, selectedTab: Binding<Int>) {
        self.userId = userId
        _selectedTab = selectedTab
        _profiles = Query(filter: #Predicate<UserProfile> { $0.cognitoUserId == userId })
        _feedings = Query(
            filter: #Predicate<FeedingRecord> { $0.userId == userId },
            sort: \FeedingRecord.feedingTime, order: .reverse
        )
        _bowels = Query(
            filter: #Predicate<BowelRecord> { $0.userId == userId },
            sort: \BowelRecord.bowelTime, order: .reverse
        )
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeaderView
                        todaySummaryCard
                        recordButtonsView

                        if viewModel.showAdvisorCard, let advice = viewModel.advisorResponse {
                            Button { selectedTab = 2 } label: {
                                AdvisorCardView(response: advice)
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .pastelNavigation(emoji: "🍼", title: "아기 일기장", color: .appPink)
            .onAppear {
                if let profile { viewModel.syncProfile(profile) }
            }
            .sheet(isPresented: $showFeedingInput) {
                FeedingInputModal { amountMl in
                    viewModel.saveFeedingRecord(
                        amountMl: amountMl,
                        userId: userId,
                        profile: profile,
                        modelContext: modelContext
                    )
                }
            }
            .sheet(isPresented: $showBowelInput) {
                BowelInputModal { time, condition in
                    viewModel.saveBowelRecord(
                        time: time,
                        condition: condition,
                        userId: userId,
                        modelContext: modelContext
                    )
                }
            }
        }
    }

    // MARK: - 서브 뷰

    private var profileHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("안녕하세요, \(profile?.motherName ?? "")님 👋")
                    .font(.subheadline).foregroundColor(.secondary)
                Text("\(profile?.babyName ?? "아기") · \(profile?.ageInMonths ?? 0)개월")
                    .font(.title2.bold())
            }
            Spacer()
            Text("🍼").font(.system(size: 40))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var todaySummaryCard: some View {
        VStack(spacing: 12) {
            Text("오늘 요약").font(.headline).frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                SummaryTile(emoji: "🍼", title: "수유",
                            value: "\(FeedingService.todayCount(records: feedings))회",
                            subtitle: "총 \(FeedingService.dailyTotal(records: feedings))ml")
                SummaryTile(emoji: "💩", title: "배변",
                            value: "\(todayBowelCount)회",
                            subtitle: lastBowelSummary)
                SummaryTile(emoji: "⏰", title: "다음 수유",
                            value: nextFeedingTimeText,
                            subtitle: "권장 시각")
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
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appPink))
            }
            Button(action: { showBowelInput = true }) {
                Label("배변 기록하기", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appGreen))
            }
        }
    }

    // MARK: - 계산 프로퍼티

    private var todayBowelCount: Int {
        bowels.filter { Calendar.current.isDateInToday($0.bowelTime) }.count
    }

    private var lastBowelSummary: String {
        guard let last = bowels.first else { return "-" }
        return "\(last.bowelCondition.emoji) 최근 \(last.bowelCondition.displayName)"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var nextFeedingTimeText: String {
        guard let last = feedings.first, let ageMonths = profile?.ageInMonths else { return "-" }
        let next = AgeCalculatorService.nextFeedingTime(lastFeedingTime: last.feedingTime, ageMonths: ageMonths)
        return Self.timeFormatter.string(from: next)
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
            Text(title).font(.caption).foregroundColor(Color(white: 0.45))
            Text(value).font(.headline.bold()).foregroundColor(Color(white: 0.1))
            Text(subtitle).font(.caption2).foregroundColor(Color(white: 0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("PastelBackground")))
    }
}
