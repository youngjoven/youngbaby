import SwiftUI
import SwiftData

struct OnboardingView: View {
    let userId: String

    @Environment(\.modelContext) private var modelContext

    @State private var babyName = ""
    @State private var babyBirthDate = Date()
    @State private var motherName = ""
    var body: some View {
        ZStack {
            Color("PastelBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // 스크롤 영역 (상태바 아래부터 시작)
                ScrollView {
                    VStack(spacing: 16) {
                        // 헤더
                        VStack(spacing: 6) {
                            Text("🍼")
                                .font(.system(size: 48))
                                .padding(.top, 16)
                            Text("아기 일기장")
                                .font(.title.bold())
                                .foregroundColor(Color("PastelPink"))
                            Text("아이의 수유·배변을 기록해요")
                                .font(.subheadline)
                                .foregroundColor(Color(white: 0.35))
                        }

                        // 입력 카드
                        VStack(spacing: 12) {
                            InputCard(title: "아이 이름", systemImage: "face.smiling") {
                                TextField(
                                    text: $babyName,
                                    prompt: Text("이름을 입력하세요").foregroundStyle(Color(white: 0.55))
                                ) { EmptyView() }
                                .textFieldStyle(.plain)
                                .foregroundColor(Color(white: 0.1))
                            }

                            InputCard(title: "아이 생년월일", systemImage: "calendar") {
                                DatePicker("", selection: $babyBirthDate, in: ...Date(), displayedComponents: .date)
                                    .labelsHidden()
                            }

                            InputCard(title: "어머니 이름", systemImage: "person.fill") {
                                TextField(
                                    text: $motherName,
                                    prompt: Text("이름을 입력하세요").foregroundStyle(Color(white: 0.55))
                                ) { EmptyView() }
                                .textFieldStyle(.plain)
                                .foregroundColor(Color(white: 0.1))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }

                // 시작하기 버튼 — 항상 하단에 고정
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
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    private var isFormValid: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !motherName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveProfile() {
        let name = babyName.trimmingCharacters(in: .whitespaces)
        let mother = motherName.trimmingCharacters(in: .whitespaces)
        let profile = UserProfile(babyName: name, babyBirthDate: babyBirthDate, motherName: mother, cognitoUserId: userId)
        modelContext.insert(profile)
        Task {
            _ = await AlarmService.requestPermission()
            try? await APIService.shared.uploadProfile(
                babyName: name,
                babyBirthDate: babyBirthDate,
                motherName: mother
            )
        }
    }
}

// MARK: - 입력 카드 컴포넌트

struct InputCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundColor(Color.appPink)
            content
                .padding(.vertical, 2)
            Divider()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
