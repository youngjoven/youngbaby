import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var confirmCode = ""
    @State private var pendingEmail = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showConfirm = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    enum Mode { case signIn, signUp }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                if showConfirm {
                    confirmView
                } else {
                    formView
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color("PastelBackground").ignoresSafeArea())
        .alert("오류", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
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
                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
            Text("가족과 함께 기록하는 아이 성장 일기")
                .font(.subheadline)
                .foregroundColor(Color(white: 0.45))
        }
    }

    // MARK: - 로그인/회원가입 폼

    private var formView: some View {
        VStack(spacing: 16) {
            // 탭 선택
            HStack(spacing: 0) {
                tabButton("로그인", selected: mode == .signIn) { mode = .signIn; clearFields() }
                tabButton("회원가입", selected: mode == .signUp) { mode = .signUp; clearFields() }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.9)))

            // 입력 필드
            VStack(spacing: 12) {
                inputField("이메일", systemImage: "envelope", text: $email, keyboard: .emailAddress)
                secureField("비밀번호", systemImage: "lock", text: $password)
                if mode == .signUp {
                    secureField("비밀번호 확인", systemImage: "lock.fill", text: $confirmPassword)
                }
            }

            if mode == .signUp {
                Text("비밀번호: 8자 이상, 대문자·소문자·숫자·특수문자(!@#$ 등) 포함")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            actionButton(
                title: mode == .signIn ? "로그인" : "회원가입",
                enabled: isFormValid,
                action: handleAction
            )
        }
    }

    // MARK: - 이메일 인증 화면

    private var confirmView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 44))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
                Text("이메일 인증")
                    .font(.title2.bold())
                Text("\(pendingEmail)으로\n발송된 인증 코드 6자리를 입력하세요.")
                    .font(.subheadline)
                    .foregroundColor(Color(white: 0.45))
                    .multilineTextAlignment(.center)
            }

            inputField("인증 코드 6자리", systemImage: "number", text: $confirmCode, keyboard: .numberPad)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            actionButton(
                title: "인증 완료",
                enabled: confirmCode.count == 6,
                action: handleConfirm
            )

            Button("← 로그인 화면으로 돌아가기") {
                showConfirm = false
                mode = .signIn
                clearFields()
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
                .background(selected ? Color(red: 0.85, green: 0.25, blue: 0.45) : Color.clear)
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
                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
            TextField("", text: text)
                .textFieldStyle(.plain)
                .keyboardType(keyboard)
                .autocapitalization(.none)
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
                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.45))
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
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(enabled && !isLoading
                          ? Color(red: 0.85, green: 0.25, blue: 0.45)
                          : Color.gray.opacity(0.4))
            )
        }
        .disabled(!enabled || isLoading)
    }

    // MARK: - 유효성 검사

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 8
        if mode == .signIn { return emailOK && passwordOK }
        return emailOK && passwordOK && password == confirmPassword
    }

    // MARK: - 액션

    private func handleAction() {
        errorMessage = ""
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if mode == .signIn {
                    let token = try await CognitoService.signIn(email: email, password: password)
                    await authManager.login(idToken: token)
                } else {
                    try await CognitoService.signUp(email: email, password: password)
                    pendingEmail = email
                    showConfirm = true
                }
            } catch {
                errorMessage = error.localizedDescription
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func handleConfirm() {
        errorMessage = ""
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await CognitoService.confirmSignUp(email: pendingEmail, code: confirmCode)
                let token = try await CognitoService.signIn(email: pendingEmail, password: password)
                await authManager.login(idToken: token)
            } catch {
                errorMessage = error.localizedDescription
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
}
