import SwiftUI

struct FeedingInputModal: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int) -> Void

    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                VStack(spacing: 32) {
                    Text("🍼")
                        .font(.system(size: 64))

                    VStack(spacing: 8) {
                        Text("수유 기록")
                            .font(.title2.bold())
                        Text("수유 시간은 지금 이 순간으로 자동 기록됩니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // 분유량 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("분유량 (ml)")
                            .font(.subheadline.bold())
                            .foregroundColor(Color("PastelPink"))
                        HStack {
                            TextField("예: 140", text: $amountText)
                                .keyboardType(.numberPad)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                            Text("ml")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                    }
                    .padding(.horizontal)

                    // 빠른 선택 버튼
                    VStack(alignment: .leading, spacing: 8) {
                        Text("빠른 선택")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            ForEach([100, 120, 140, 160, 180], id: \.self) { amount in
                                Button("\(amount)ml") {
                                    amountText = "\(amount)"
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(amountText == "\(amount)" ? Color("PastelPink") : Color.white)
                                )
                                .foregroundColor(amountText == "\(amount)" ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: saveAndDismiss) {
                        Text("기록하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isValid ? Color("PastelPink") : Color.gray.opacity(0.4))
                            )
                    }
                    .disabled(!isValid)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private var isValid: Bool {
        guard let amount = Int(amountText) else { return false }
        return amount > 0
    }

    private func saveAndDismiss() {
        guard let amount = Int(amountText), amount > 0 else { return }
        onSave(amount)
        dismiss()
    }
}
