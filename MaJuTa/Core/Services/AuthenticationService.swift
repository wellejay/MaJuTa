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
                        await waitForFirebaseSession()
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
                    await waitForFirebaseSession()
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

    /// Firebase Auth persists its session in Keychain and restores it asynchronously on launch.
    /// Biometric auth (Face ID) completes in milliseconds — before the token is restored.
    /// This waits up to 3 seconds for the Firebase UID to appear before setting up listeners.
    private func waitForFirebaseSession() async {
        guard FirebaseAuthService.shared.firebaseUID == nil else { return }
        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms × 30 = 3s max
            if FirebaseAuthService.shared.firebaseUID != nil { return }
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
