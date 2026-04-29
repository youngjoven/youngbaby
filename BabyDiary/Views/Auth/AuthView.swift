import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var vm = AuthViewModel()
    @AppStorage("autoLoginEnabled") private var autoLoginEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                if vm.showConfirm {
                    confirmView
                } else {
                    formView
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color("PastelBackground").ignoresSafeArea())
        .alert("오류", isPresented: $vm.showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    // MARK: - 헤더

    private var header: some View {
        VStack(spacing: 6) {
            Text("🍼")
                .font(.system(size: 56))
                .padding(.top, 20)
            Text("아기 일기장")
                .font(.title.bold())
                .foregroundColor(Color.appPink)
            Text("가족과 함께 기록하는 아이 성장 일기")
                .font(.subheadline)
                .foregroundColor(Color(white: 0.45))
        }
    }

    // MARK: - 로그인/회원가입 폼

    private var formView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                tabButton("로그인", selected: vm.mode == .signIn) { vm.switchMode(to: .signIn) }
                tabButton("회원가입", selected: vm.mode == .signUp) { vm.switchMode(to: .signUp) }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.9)))

            VStack(spacing: 12) {
                inputField("이메일", systemImage: "envelope", text: $vm.email, keyboard: .emailAddress)
                secureField("비밀번호", systemImage: "lock", text: $vm.password)
                if vm.mode == .signUp {
                    secureField("비밀번호 확인", systemImage: "lock.fill", text: $vm.confirmPassword)
                }
            }

            if vm.mode == .signUp {
                Text("비밀번호: 8자 이상, 대문자·소문자·숫자·특수문자(!@#$ 등) 포함")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if vm.mode == .signIn {
                Toggle(isOn: $autoLoginEnabled) {
                    Label("자동 로그인", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.3))
                }
                .tint(Color.appPink)
                .padding(.horizontal, 4)
            }

            actionButton(
                title: vm.mode == .signIn ? "로그인" : "회원가입",
                enabled: vm.isFormValid,
                action: { vm.handleAction(authManager: authManager) }
            )
        }
    }

    // MARK: - 이메일 인증 화면

    private var confirmView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 44))
                    .foregroundColor(Color.appPink)
                Text("이메일 인증")
                    .font(.title2.bold())
                Text("\(vm.pendingEmail)으로\n발송된 인증 코드 6자리를 입력하세요.")
                    .font(.subheadline)
                    .foregroundColor(Color(white: 0.45))
                    .multilineTextAlignment(.center)
            }

            inputField("인증 코드 6자리", systemImage: "number", text: $vm.confirmCode, keyboard: .numberPad)

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            actionButton(
                title: "인증 완료",
                enabled: vm.confirmCode.count == 6,
                action: { vm.handleConfirm(authManager: authManager) }
            )

            Button("← 로그인 화면으로 돌아가기") {
                vm.showConfirm = false
                vm.switchMode(to: .signIn)
            }
            .font(.caption)
            .foregroundColor(Color(white: 0.5))
        }
    }

    // MARK: - 재사용 컴포넌트

    private func tabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(selected ? .white : Color(white: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.appPink : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func inputField(
        _ title: String, systemImage: String,
        text: Binding<String>, keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundColor(Color.appPink)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Divider()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func secureField(_ title: String, systemImage: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundColor(Color.appPink)
            SecureField("", text: text)
                .textFieldStyle(.plain)
            Divider()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func actionButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(enabled && !vm.isLoading
                          ? Color.appPink
                          : Color.gray.opacity(0.4))
            )
        }
        .disabled(!enabled || vm.isLoading)
    }
}
