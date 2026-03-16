import SwiftUI
import SwiftData

struct RecordView: View {
    @Query(sort: \FeedingRecord.feedingTime, order: .reverse) private var feedings: [FeedingRecord]
    @Query(sort: \BowelRecord.bowelTime, order: .reverse) private var bowels: [BowelRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                VStack(spacing: 0) {
                    // 통계 요약
                    statisticsView
                        .padding()

                    // 수유 / 배변 탭 전환
                    Picker("", selection: $selectedTab) {
                        Text("수유 기록").tag(0)
                        Text("배변 기록").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 기록 목록
                    List {
                        if selectedTab == 0 {
                            ForEach(feedings) { record in
                                FeedingRowView(record: record)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { modelContext.delete(feedings[$0]) }
                            }
                        } else {
                            ForEach(bowels) { record in
                                BowelRowView(record: record)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { modelContext.delete(bowels[$0]) }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color("PastelBackground"))
                }
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 통계 요약 카드

    private var statisticsView: some View {
        VStack(spacing: 12) {
            Text("통계")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                StatCard(title: "평균 수유 간격",
                         value: averageIntervalText,
                         color: Color("PastelPink"))
                StatCard(title: "1회 평균 분유량",
                         value: averageAmountText,
                         color: Color("PastelMint"))
                StatCard(title: "오늘 총 분유량",
                         value: "\(FeedingService.dailyTotal(records: feedings))ml",
                         color: Color("PastelPurple"))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var averageIntervalText: String {
        guard let avg = FeedingService.averageInterval(records: feedings) else { return "-" }
        return String(format: "%.1f시간", avg)
    }

    private var averageAmountText: String {
        guard let avg = FeedingService.averageAmount(records: feedings) else { return "-" }
        return String(format: "%.0fml", avg)
    }
}

// MARK: - 수유 기록 행

struct FeedingRowView: View {
    let record: FeedingRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.feedingTime, style: .time)
                    .font(.headline)
                Text(record.feedingTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("🍼")
                Text("\(record.amountMl)ml")
                    .font(.headline)
                    .foregroundColor(Color("PastelPink"))
            }
            if record.syncedAt == nil {
                Image(systemName: "icloud.slash")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 배변 기록 행

struct BowelRowView: View {
    let record: BowelRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.bowelTime, style: .time)
                    .font(.headline)
                Text(record.bowelTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Text(record.bowelCondition.emoji)
                Text(record.bowelCondition.displayName)
                    .font(.headline)
                    .foregroundColor(Color("PastelMint"))
            }
            if record.syncedAt == nil {
                Image(systemName: "icloud.slash")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 통계 카드 컴포넌트

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}
