import Foundation
import FirebaseAuth
import CryptoKit

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published var isEmailVerified: Bool = false
    @Published var firebaseUID: String? = nil

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.firebaseUID = user?.uid
                self?.isEmailVerified = user?.isEmailVerified ?? false
            }
        }
    }

    // MARK: - Account Creation
    func createAccount(email: String, pin: String, userId: UUID) async throws -> String {
        let password = firebasePassword(pin: pin, userId: userId)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        firebaseUID = result.user.uid
        // Send verification email with a continueURL that redirects back to the app
        // via the majuta:// custom URL scheme (registered in Info.plist).
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://majuta-880aa.web.app/verified")
        settings.handleCodeInApp = false
        settings.setIOSBundleID("com.majuta.app")
        try? await result.user.sendEmailVerification(with: settings)
        return result.user.uid
    }

    // MARK: - Sign In
    /// Signs in to Firebase Auth using the same deterministic password.
    @discardableResult
    func signIn(email: String, pin: String, userId: UUID) async -> Bool {
        let password = firebasePassword(pin: pin, userId: userId)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            firebaseUID = result.user.uid
            isEmailVerified = result.user.isEmailVerified
            return true
        } catch {
            return false
        }
    }

    // MARK: - Email Verification
    func resendVerificationEmail() async throws {
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://majuta-880aa.web.app/verified")
        settings.handleCodeInApp = false
        settings.setIOSBundleID("com.majuta.app")
        try await Auth.auth().currentUser?.sendEmailVerification(with: settings)
    }

    /// Called when the app receives a majuta://email-verified deep link.
    /// Reloads the user's verification status from Firebase.
    func handleEmailVerifiedDeepLink() async {
        await reloadVerificationStatus()
    }

    func reloadVerificationStatus() async {
        do {
            try await Auth.auth().currentUser?.reload()
            isEmailVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        } catch {}
    }

    // MARK: - Sign Out
    func signOut() {
        try? Auth.auth().signOut()
        firebaseUID = nil
        isEmailVerified = false
    }

    // MARK: - Helper
    func firebasePassword(pin: String, userId: UUID) -> String {
        let input = "fb_\(pin)_\(userId.uuidString)_majuta"
        let hash = SHA256.hash(data: Data(input.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(32))
    }
}
