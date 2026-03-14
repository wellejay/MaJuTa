import SwiftUI
import LocalAuthentication

@MainActor
final class AuthenticationService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    @Published var showRegistration: Bool = false
    @Published var showEmailVerification: Bool = false
    @Published var selectedUser: UserProfile?

    func authenticate() async {
        authError = nil
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "قم بتسجيل الدخول إلى MaJuTa"
                )
                if success {
                    isAuthenticated = true
                    if let user = selectedUser ?? UserService.shared.lastLoggedInUser() {
                        UserService.shared.setCurrentUser(user)
                        DataStore.shared.loadForCurrentUser()
                    }
                }
            } catch {
                // Biometric failed — fall through to full device auth (passcode)
                await authenticateWithDevicePasscode()
            }
        } else {
            // No biometrics enrolled — use passcode directly
            await authenticateWithDevicePasscode()
        }
    }

    func authenticate(as user: UserProfile) async {
        selectedUser = user
        await authenticate()
    }

    private func authenticateWithDevicePasscode() async {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "أدخل رمز الجهاز للوصول إلى MaJuTa"
            )
            isAuthenticated = success
            if success {
                if let user = selectedUser ?? UserService.shared.lastLoggedInUser() {
                    UserService.shared.setCurrentUser(user)
                    DataStore.shared.loadForCurrentUser()
                }
            } else {
                authError = "المصادقة فشلت. حاول مجدداً."
            }
        } catch {
            authError = error.localizedDescription
            isAuthenticated = false
        }
    }

    func lock() {
        isAuthenticated = false
        authError = nil
        selectedUser = nil
        UserService.shared.logout()
    }

    var biometricType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }
}
