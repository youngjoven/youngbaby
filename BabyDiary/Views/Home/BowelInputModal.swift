import SwiftUI

struct BowelInputModal: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Date, BowelCondition) -> Void

    @State private var selectedCondition: BowelCondition = .normal

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 이모지 + 타이틀
                            VStack(spacing: 8) {
                                Text("💩")
                                    .font(.system(size: 56))
                                    .padding(.top, 20)
                                Text("배변 기록")
                                    .font(.title2.bold())
                                    .foregroundColor(Color(white: 0.1))
                                Text("지금 이 순간으로 자동 기록됩니다.")
                                    .font(.subheadline)
                                    .foregroundColor(Color(white: 0.45))
                            }

                            // 배변 상태 선택
                            VStack(alignment: .leading, spacing: 10) {
                                Text("배변 상태")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.45))

                                ForEach(BowelCondition.allCases, id: \.self) { condition in
                                    Button(action: { selectedCondition = condition }) {
                                        HStack {
                                            Text(condition.emoji)
                                                .font(.title2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(condition.displayName)
                                                    .font(.headline)
                                                    .foregroundColor(Color(white: 0.1))
                                                Text(condition.description)
                                                    .font(.caption)
                                                    .foregroundColor(Color(white: 0.45))
                                            }
                                            Spacer()
                                            if selectedCondition == condition {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.45))
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedCondition == condition
                                                      ? Color(red: 0.1, green: 0.6, blue: 0.45).opacity(0.12)
                                                      : Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            selectedCondition == condition
                                                            ? Color(red: 0.1, green: 0.6, blue: 0.45)
                                                            : Color.clear,
                                                            lineWidth: 2
                                                        )
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.04), radius: 6)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }

                    // 기록하기 버튼 — 하단 고정
                    Button(action: saveAndDismiss) {
                        Text("기록하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.45))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.45))
                }
            }
        }
    }

    private func saveAndDismiss() {
        onSave(Date(), selectedCondition)
        dismiss()
    }
}
