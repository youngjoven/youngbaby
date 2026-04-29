import SwiftUI
import SwiftData

/// 로그인 상태에 따라 화면 분기
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isInitializing {
                splashView
            } else if !authManager.isLoggedIn {
                AuthView()
            } else {
                LoggedInRootView(userId: authManager.userId)
            }
        }
        .task {
            await authManager.tryAutoLogin()
        }
    }

    private var splashView: some View {
        ZStack {
            Color("PastelBackground").ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🍼").font(.system(size: 56))
                ProgressView().tint(Color.appPink)
            }
        }
    }
}

/// 로그인된 상태에서 userId 기반으로 프로필 확인 → 복원 → 온보딩 → 메인탭
struct LoggedInRootView: View {
    let userId: String

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var feedings: [FeedingRecord]
    @Query private var bowels: [BowelRecord]
    @State private var isRestoring = false

    init(userId: String) {
        self.userId = userId
        _profiles = Query(filter: #Predicate<UserProfile> { $0.cognitoUserId == userId })
        _feedings = Query(filter: #Predicate<FeedingRecord> { $0.userId == userId })
        _bowels = Query(filter: #Predicate<BowelRecord> { $0.userId == userId })
    }

    var body: some View {
        Group {
            if isRestoring {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("데이터 불러오는 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if profiles.isEmpty {
                OnboardingView(userId: userId)
            } else {
                MainTabView(userId: userId)
            }
        }
        .task(id: userId) {
            guard !userId.isEmpty else { return }
            await restoreFromServerIfNeeded()
        }
    }

    /// 로컬에 현재 유저 프로필이 없으면 서버에서 복원 시도
    private func restoreFromServerIfNeeded() async {
        guard profiles.isEmpty else { return }

        isRestoring = true
        defer { isRestoring = false }

        do {
            guard let serverProfile = try await APIService.shared.fetchProfile() else { return }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let birthDate = dateFormatter.date(from: serverProfile.babyBirthDate) else { return }

            modelContext.insert(UserProfile(
                babyName: serverProfile.babyName,
                babyBirthDate: birthDate,
                motherName: serverProfile.motherName ?? "",
                cognitoUserId: userId
            ))

            let now = Date()
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now)!
            let iso = ISO8601DateFormatter()

            // 기존 로컬 feedingTime 집합 (중복 방지)
            let existingFeedingTimes = Set(feedings.map { iso.string(from: $0.feedingTime) })

            let serverFeedings = try await APIService.shared.fetchFeedings(from: ninetyDaysAgo, to: now)
            for f in serverFeedings {
                guard !existingFeedingTimes.contains(f.feedingTime),
                      let time = iso.date(from: f.feedingTime) else { continue }
                let record = FeedingRecord(userId: userId, feedingTime: time, amountMl: f.amountMl)
                record.syncedAt = now
                modelContext.insert(record)
            }

            // 기존 로컬 bowelTime 집합 (중복 방지)
            let existingBowelTimes = Set(bowels.map { iso.string(from: $0.bowelTime) })

            let serverBowels = try await APIService.shared.fetchBowels(from: ninetyDaysAgo, to: now)
            for b in serverBowels {
                guard !existingBowelTimes.contains(b.bowelTime),
                      let time = iso.date(from: b.bowelTime),
                      let condition = BowelCondition(rawValue: b.condition) else { continue }
                let record = BowelRecord(userId: userId, bowelTime: time, condition: condition)
                record.syncedAt = now
                modelContext.insert(record)
            }
        } catch {
            print("[Restore] \(error)")
        }
    }
}
