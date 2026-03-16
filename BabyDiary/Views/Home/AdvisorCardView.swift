import SwiftUI

/// 수유 기록 직후 자동 표시되는 AI 추천 카드
struct AdvisorCardView: View {
    let response: AdvisorResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("PastelPurple"))
                Text("AI 수유 어드바이저")
                    .font(.headline)
                    .foregroundColor(Color("PastelPurple"))
                Spacer()
            }

            Divider()

            AdviceRow(emoji: "⏰", text: response.nextFeedingAdvice)
            AdviceRow(emoji: "🍼", text: response.amountAdvice)
            AdviceRow(emoji: "💬", text: response.overallOpinion)

            Text(response.disclaimer)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PastelPurple").opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("PastelPurple").opacity(0.3), lineWidth: 1))
        )
    }
}

private struct AdviceRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
