import SwiftUI

struct InsightsView: View {
    @State private var insights: [InsightItem] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                if isLoading {
                    ProgressView("인사이트 분석 중...")
                } else if insights.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(insights) { item in
                                InsightCard(item: item)
                            }

                            // 면책 문구
                            Text("모든 인사이트는 참고용이며, 의료적 진단을 대체하지 않습니다.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding()
                    }
                }
            }
            .pastelNavigation(emoji: "📊", title: "인사이트", color: .appPurple)
            .task { await loadInsights() }
            .refreshable { await loadInsights() }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.appPurple.opacity(0.4))
            Text("3일 이상 기록이 쌓이면\n주간 인사이트가 표시됩니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func loadInsights() async {
        isLoading = true
        insights = (try? await APIService.shared.fetchInsights()) ?? []
        isLoading = false
    }
}

// MARK: - 인사이트 카드

struct InsightCard: View {
    let item: InsightItem

    private var emoji: String {
        switch item.insightType {
        case "amount_change":    return "📊"
        case "interval_change":  return "⏱️"
        case "bowel_pattern":    return "💩"
        case "age_comparison":   return "📋"
        case "feeding_bowel":    return "🔗"
        default:                 return "💡"
        }
    }

    private var cardColor: Color {
        switch item.insightType {
        case "amount_change":    return Color.appPink
        case "interval_change":  return Color.appGreen
        case "bowel_pattern":    return Color.orange
        case "age_comparison":   return Color.appPurple
        default:                 return Color.blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emoji)
                    .font(.title2)
                Text(item.insightType.insightTypeDisplayName)
                    .font(.headline)
                    .foregroundColor(cardColor)
                Spacer()
                Text(item.generatedAt.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(item.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardColor.opacity(0.25), lineWidth: 1))
        )
    }
}

// MARK: - 헬퍼 Extension

private extension String {
    var insightTypeDisplayName: String {
        switch self {
        case "amount_change":   return "분유량 변화 감지"
        case "interval_change": return "수유 간격 변화"
        case "bowel_pattern":   return "배변 이상 패턴"
        case "age_comparison":  return "월령별 권장량 비교"
        case "feeding_bowel":   return "수유-배변 연관"
        default:                return "인사이트"
        }
    }

    var formattedDate: String {
        guard let date = Self._isoFormatter.date(from: self) else { return self }
        return Self._displayFormatter.string(from: date)
    }

    private nonisolated(unsafe) static let _isoFormatter = ISO8601DateFormatter()
    private nonisolated(unsafe) static let _displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f
    }()
}
