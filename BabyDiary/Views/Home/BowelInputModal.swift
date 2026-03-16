import SwiftUI

struct BowelInputModal: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Date, BowelCondition) -> Void

    @State private var bowelTime = Date()
    @State private var selectedCondition: BowelCondition = .normal

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PastelBackground").ignoresSafeArea()

                VStack(spacing: 32) {
                    Text("💩")
                        .font(.system(size: 64))

                    Text("배변 기록")
                        .font(.title2.bold())

                    // 배변 시간 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("배변 시간")
                            .font(.subheadline.bold())
                            .foregroundColor(Color("PastelMint"))
                        DatePicker("배변 시간", selection: $bowelTime, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .shadow(color: .black.opacity(0.05), radius: 8)
                    }
                    .padding(.horizontal)

                    // 배변 상태 선택
                    VStack(alignment: .leading, spacing: 12) {
                        Text("배변 상태")
                            .font(.subheadline.bold())
                            .foregroundColor(Color("PastelMint"))

                        ForEach(BowelCondition.allCases, id: \.self) { condition in
                            Button(action: { selectedCondition = condition }) {
                                HStack {
                                    Text(condition.emoji)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(condition.displayName)
                                            .font(.headline)
                                        Text(condition.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedCondition == condition {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("PastelMint"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedCondition == condition ? Color("PastelMint").opacity(0.15) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedCondition == condition ? Color("PastelMint") : Color.clear, lineWidth: 2)
                                        )
                                )
                                .shadow(color: .black.opacity(0.04), radius: 6)
                            }
                            .foregroundColor(.primary)
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
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color("PastelMint")))
                    }
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

    private func saveAndDismiss() {
        onSave(bowelTime, selectedCondition)
        dismiss()
    }
}
