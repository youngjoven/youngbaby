import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var babyName = ""
    @State private var babyBirthDate = Date()
    @State private var motherName = ""
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            Color("PastelBackground").ignoresSafeArea()

            VStack(spacing: 32) {
                // 헤더
                VStack(spacing: 8) {
                    Text("🍼")
                        .font(.system(size: 64))
                    Text("아기 일기장")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color("PastelPink"))
                    Text("아이의 수유·배변을 기록해요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // 입력 카드
                VStack(spacing: 20) {
                    InputCard(title: "아이 이름", systemImage: "face.smiling") {
                        TextField("이름을 입력하세요", text: $babyName)
                            .textFieldStyle(.plain)
                    }

                    InputCard(title: "아이 생년월일", systemImage: "calendar") {
                        DatePicker("", selection: $babyBirthDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                    }

                    InputCard(title: "어머니 이름", systemImage: "person.fill") {
                        TextField("이름을 입력하세요", text: $motherName)
                            .textFieldStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // 시작 버튼
                Button(action: saveProfile) {
                    Text("시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isFormValid ? Color("PastelPink") : Color.gray.opacity(0.4))
                        )
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    private var isFormValid: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !motherName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveProfile() {
        let profile = UserProfile(
            babyName: babyName.trimmingCharacters(in: .whitespaces),
            babyBirthDate: babyBirthDate,
            motherName: motherName.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(profile)
        Task { await AlarmService.requestPermission() }
    }
}

// MARK: - 입력 카드 컴포넌트

struct InputCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundColor(Color("PastelPink"))
            content
                .padding(.vertical, 4)
            Divider()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
