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
                        .padding(.horizontal)
                        .padding(.top, 6)
                        .padding(.bottom, 10)

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
                                FeedingRowView(record: record) {
                                    modelContext.delete(record)
                                }
                            }
                        } else {
                            ForEach(bowels) { record in
                                BowelRowView(record: record) {
                                    modelContext.delete(record)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color("PastelBackground"))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("PastelBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("📋")
                            .font(.subheadline)
                        Text("기록")
                            .font(.headline.bold())
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
                    }
                }
            }
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
                         color: Color(red: 0.85, green: 0.25, blue: 0.45))
                StatCard(title: "1회 평균 분유량",
                         value: averageAmountText,
                         color: Color(red: 0.1, green: 0.6, blue: 0.45))
                StatCard(title: "오늘 총 분유량",
                         value: "\(FeedingService.dailyTotal(records: feedings))ml",
                         color: Color(red: 0.5, green: 0.2, blue: 0.8))
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
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.feedingTime, style: .time)
                    .font(.headline)
                Text(record.feedingTime, style: .date)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()
            HStack(spacing: 4) {
                Text("🍼")
                Text("\(record.amountMl)ml")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
            }
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(Color.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 배변 기록 행

struct BowelRowView: View {
    let record: BowelRecord
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.bowelTime, style: .time)
                    .font(.headline)
                Text(record.bowelTime, style: .date)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()
            HStack(spacing: 4) {
                Text(record.bowelCondition.emoji)
                Text(record.bowelCondition.displayName)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.45))
            }
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(Color.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
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
