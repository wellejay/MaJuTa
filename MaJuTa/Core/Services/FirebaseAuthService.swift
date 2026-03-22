import Foundation
import FirebaseAuth
import CryptoKit
import CommonCrypto
import OSLog

private let logger = Logger(subsystem: "com.majuta.app", category: "firebase-auth")

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
        let password = firebasePasswordV3(pin: pin, userId: userId)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        firebaseUID = result.user.uid
        // Send standard Firebase verification email (no custom redirect needed)
        try? await result.user.sendEmailVerification()
        return result.user.uid
    }

    // MARK: - Sign In
    /// Signs in to Firebase Auth using migration-aware password derivation.
    /// Tries V3 (310k iterations) → V2 (100k) → V1 (SHA256 legacy), migrating up to V3 on success.
    @discardableResult
    func signIn(email: String, pin: String, userId: UUID) async -> Bool {
        let passwordV3 = firebasePasswordV3(pin: pin, userId: userId)

        // Fast path: V3 (new accounts and migrated users)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: passwordV3)
            firebaseUID = result.user.uid
            isEmailVerified = result.user.isEmailVerified
            return true
        } catch {
            logger.info("signIn V3 failed, trying V2: \(error.localizedDescription, privacy: .private)")
        }

        // Fallback: V2 (100k iterations — migrate to V3)
        let passwordV2 = firebasePasswordV2(pin: pin, userId: userId)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: passwordV2)
            firebaseUID = result.user.uid
            isEmailVerified = result.user.isEmailVerified
            do {
                try await result.user.updatePassword(to: passwordV3)
                logger.info("Firebase password migrated from V2 to V3 for user \(userId, privacy: .private)")
            } catch {
                logger.warning("Firebase password migration V2→V3 failed (will retry): \(error.localizedDescription, privacy: .private)")
            }
            return true
        } catch {
            logger.info("signIn V2 failed, trying V1: \(error.localizedDescription, privacy: .private)")
        }

        // Fallback: V1 (SHA256 legacy — migrate to V3)
        let passwordV1 = firebasePassword(pin: pin, userId: userId)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: passwordV1)
            firebaseUID = result.user.uid
            isEmailVerified = result.user.isEmailVerified
            do {
                try await result.user.updatePassword(to: passwordV3)
                logger.info("Firebase password migrated from V1 to V3 for user \(userId, privacy: .private)")
            } catch {
                logger.warning("Firebase password migration V1→V3 failed (will retry): \(error.localizedDescription, privacy: .private)")
            }
            return true
        } catch {
            logger.error("signIn failed (V1, V2, V3 all failed): \(error.localizedDescription, privacy: .private)")
            return false
        }
    }

    // MARK: - Email Verification
    func resendVerificationEmail() async throws {
        try await Auth.auth().currentUser?.sendEmailVerification()
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
        } catch {
            logger.error("reloadVerificationStatus failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Sign Out
    func signOut() {
        try? Auth.auth().signOut()
        firebaseUID = nil
        isEmailVerified = false
    }

    // MARK: - Delete Account
    /// Permanently deletes the Firebase Auth account. Requires recent sign-in.
    func deleteCurrentUser() async throws {
        try await Auth.auth().currentUser?.delete()
        firebaseUID = nil
        isEmailVerified = false
    }

    // MARK: - Password Derivation

    /// Legacy V1 Firebase password derivation (SHA256, single round).
    /// Used only during migration — new accounts use firebasePasswordV2().
    func firebasePassword(pin: String, userId: UUID) -> String {
        let input = "fb_\(pin)_\(userId.uuidString)_majuta"
        let hash = SHA256.hash(data: Data(input.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(32))
    }

    /// Derives Firebase Auth password using PBKDF2-HMAC-SHA256.
    /// V2: 100,000 iterations (legacy — kept for migration reads only)
    /// Input: "fb_v2_<PIN>_<UUID>_majuta"
    /// Salt: SHA256 of the userId string (deterministic, no storage needed)
    func firebasePasswordV2(pin: String, userId: UUID) -> String {
        let input = "fb_v2_\(pin)_\(userId.uuidString)_majuta"
        let salt = Data(SHA256.hash(data: Data(userId.uuidString.utf8)))
        let derived = pbkdf2SHA256(password: input, salt: salt, iterations: 100_000, keyLength: 32)
        return derived.map { String(format: "%02x", $0) }.joined()
    }

    /// Derives Firebase Auth password using PBKDF2-HMAC-SHA256.
    /// V3: 310,000 iterations (OWASP 2023 recommendation).
    /// Input: "fb_v3_<PIN>_<UUID>_majuta"
    /// Salt: SHA256 of the userId string (deterministic, no storage needed)
    func firebasePasswordV3(pin: String, userId: UUID) -> String {
        let input = "fb_v3_\(pin)_\(userId.uuidString)_majuta"
        let salt = Data(SHA256.hash(data: Data(userId.uuidString.utf8)))
        let derived = pbkdf2SHA256(password: input, salt: salt, iterations: 310_000, keyLength: 32)
        return derived.map { String(format: "%02x", $0) }.joined()
    }

    private func pbkdf2SHA256(password: String, salt: Data, iterations: Int, keyLength: Int) -> Data {
        var derivedKey = Data(repeating: 0, count: keyLength)
        let passwordData = Data(password.utf8)
        _ = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, passwordData.count,
                        saltBytes.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress, keyLength
                    )
                }
            }
        }
        return derivedKey
    }
}
