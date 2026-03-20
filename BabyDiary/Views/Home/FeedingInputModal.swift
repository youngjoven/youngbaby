import SwiftUI

struct FeedingInputModal: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int) -> Void

    @State private var amount: Double = 120

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            Text("🍼")
                                .font(.system(size: 64))
                                .padding(.top, 20)

                            VStack(spacing: 8) {
                                Text("수유 기록")
                                    .font(.title2.bold())
                                    .foregroundColor(Color(white: 0.1))
                                Text("수유 시간은 지금 이 순간으로 자동 기록됩니다.")
                                    .font(.subheadline)
                                    .foregroundColor(Color(white: 0.45))
                                    .multilineTextAlignment(.center)
                            }

                            // 분유량 표시
                            VStack(spacing: 4) {
                                HStack(alignment: .lastTextBaseline, spacing: 6) {
                                    Text("\(Int(amount))")
                                        .font(.system(size: 80, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
                                    Text("ml")
                                        .font(.title)
                                        .foregroundColor(Color(white: 0.4))
                                }
                            }

                            // 슬라이더
                            VStack(spacing: 14) {
                                Slider(value: $amount, in: 20...300, step: 10)
                                    .tint(Color(red: 0.85, green: 0.25, blue: 0.45))

                                HStack {
                                    Text("20ml")
                                        .font(.caption)
                                        .foregroundColor(Color(white: 0.5))
                                    Spacer()
                                    Text("160ml")
                                        .font(.caption)
                                        .foregroundColor(Color(white: 0.5))
                                    Spacer()
                                    Text("300ml")
                                        .font(.caption)
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                            .shadow(color: .black.opacity(0.06), radius: 8)
                            .padding(.horizontal)

                            // 월령별 권장량 안내
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
                                Text("신생아 60~90ml · 2개월 120ml · 4개월+ 150~200ml")
                                    .font(.caption)
                                    .foregroundColor(Color(white: 0.45))
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                    }

                    // 기록하기 버튼 하단 고정
                    Button(action: saveAndDismiss) {
                        Text("기록하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.85, green: 0.25, blue: 0.45))
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
                        .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
                }
            }
        }
    }

    private func saveAndDismiss() {
        onSave(Int(amount))
        dismiss()
    }
}
