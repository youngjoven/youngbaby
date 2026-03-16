import SwiftUI

struct AdvisorView: View {
    @State private var response: AdvisorResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더
                        VStack(spacing: 8) {
                            Text("✨")
                                .font(.system(size: 48))
                            Text("AI 수유 어드바이저")
                                .font(.title2.bold())
                            Text("최근 7일 수유·배변 기록을 분석합니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)

                        if isLoading {
                            ProgressView("분석 중...")
                                .padding()
                        } else if let response = response {
                            advisorContent(response: response)
                        } else {
                            emptyStateView
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("어드바이저")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadAdvice() }
            .refreshable { await loadAdvice() }
        }
    }

    // MARK: - 추천 내용

    private func advisorContent(response: AdvisorResponse) -> some View {
        VStack(spacing: 16) {
            AdvisorItemCard(
                emoji: "⏰",
                title: "다음 수유 시간",
                content: response.nextFeedingAdvice,
                color: Color("PastelPink")
            )
            AdvisorItemCard(
                emoji: "🍼",
                title: "분유량 조언",
                content: response.amountAdvice,
                color: Color("PastelMint")
            )
            AdvisorItemCard(
                emoji: "💬",
                title: "수유·배변 종합 의견",
                content: response.overallOpinion,
                color: Color("PastelPurple")
            )

            // 면책 문구
            Text(response.disclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(Color("PastelPurple").opacity(0.5))
            Text("수유 기록이 쌓이면\nAI 추천이 표시됩니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - 데이터 로드

    private func loadAdvice() async {
        isLoading = true
        errorMessage = nil
        do {
            response = try await APIService.shared.fetchAdvice()
        } catch {
            errorMessage = "추천을 불러오지 못했습니다."
        }
        isLoading = false
    }
}

// MARK: - 어드바이저 아이템 카드

struct AdvisorItemCard: View {
    let emoji: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
        )
    }
}
