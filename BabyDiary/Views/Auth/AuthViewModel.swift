import Foundation

@MainActor
@Observable
final class AuthViewModel {
    enum Mode { case signIn, signUp }

    var mode: Mode = .signIn
    var email = ""
    var password = ""
    var confirmPassword = ""
    var confirmCode = ""
    var isLoading = false
    var errorMessage = ""
    var showConfirm = false
    var showAlert = false
    var alertMessage = ""

    var pendingEmail = ""

    var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 8
        if mode == .signIn { return emailOK && passwordOK }
        return emailOK && passwordOK && password == confirmPassword
    }

    func handleAction(authManager: AuthManager) {
        errorMessage = ""
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if mode == .signIn {
                    let tokens = try await CognitoService.signIn(email: email, password: password)
                    await authManager.login(idToken: tokens.idToken, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
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

    func handleConfirm(authManager: AuthManager) {
        errorMessage = ""
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await CognitoService.confirmSignUp(email: pendingEmail, code: confirmCode)
                let tokens = try await CognitoService.signIn(email: pendingEmail, password: password)
                await authManager.login(idToken: tokens.idToken, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            } catch {
                errorMessage = error.localizedDescription
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }

    func switchMode(to newMode: Mode) {
        mode = newMode
        clearFields()
    }
}
