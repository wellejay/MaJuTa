import Foundation
import CryptoKit
import CommonCrypto

@MainActor
final class UserService: ObservableObject {
    static let shared = UserService()

    @Published private(set) var registeredUsers: [UserProfile] = []
    @Published private(set) var registeredHouseholds: [RegisteredHousehold] = []
    @Published private(set) var currentUser: UserProfile? = nil

    private static let usersKey = "registered_users_v1"
    private static let householdsKey = "registered_households_v1"

    private init() {
        loadUsersFromKeychain()
    }

    // MARK: - Registration

    func register(name: String, username: String, email: String,
                  phoneNumber: String, pin: String) async -> UserProfile {
        // S6: Best-effort Firestore uniqueness check (supplements local check)
        let serverAvailable = await FirestoreService.shared.isUsernameAvailable(username)
        if !serverAvailable {
            // Username taken on server — fall back to existing user if somehow registered
        }
        let householdId = UUID()
        var user = UserProfile(
            name: name,
            username: username.lowercased(),
            email: email.lowercased(),
            phoneNumber: phoneNumber,
            householdId: householdId,
            role: .owner,
            avatarColorHex: avatarColor(for: registeredUsers.count)
        )
        let household = RegisteredHousehold(id: householdId, name: "\(name) عائلة", ownerUserId: user.id)

        // Firebase Auth — store UID in profile
        if let uid = try? await FirebaseAuthService.shared.createAccount(email: email, pin: pin, userId: user.id) {
            user.firebaseUID = uid
            // Write reverse-lookup and AWAIT confirmation so subsequent Firestore
            // writes and listener setups see the authLookup entry in security rules.
            await FirestoreService.shared.saveAuthLookup(firebaseUID: uid, userId: user.id, householdId: householdId)
        }

        // PIN stays in Keychain
        KeychainService.set(hashPIN(pin, userId: user.id), for: "pin_\(user.id.uuidString)")

        registeredUsers.append(user)
        registeredHouseholds.append(household)
        saveUsersToKeychain()

        // Save to Firestore (authLookup is already confirmed above)
        FirestoreService.shared.saveUser(user)
        FirestoreService.shared.saveHousehold(household)

        // Generate and save invite code to Firestore
        let code = generateInviteCode(for: householdId)
        FirestoreService.shared.saveInviteCode(code, householdId: householdId)

        return user
    }

    func isUsernameAvailable(_ username: String) -> Bool {
        let lower = username.lowercased()
        return !registeredUsers.contains { $0.username.lowercased() == lower }
    }

    func isEmailAvailable(_ email: String) -> Bool {
        let lower = email.lowercased()
        return !registeredUsers.contains { $0.email.lowercased() == lower }
    }

    func isPhoneAvailable(_ phone: String) -> Bool {
        let incomingDigits = phone.filter { $0.isNumber }
        let incoming9 = String(incomingDigits.suffix(9))
        guard !incoming9.isEmpty else { return true }
        return !registeredUsers.contains { existing in
            let storedDigits = existing.phoneNumber.filter { $0.isNumber }
            let stored9 = String(storedDigits.suffix(9))
            return stored9 == incoming9
        }
    }

    // MARK: - Authentication

    func verifyPIN(_ pin: String, for user: UserProfile) -> Bool {
        guard let stored = KeychainService.getString(for: "pin_\(user.id.uuidString)") else { return false }

        if stored.hasPrefix("pbkdf2:") {
            // New PBKDF2 format: "pbkdf2:<base64hash>:<base64salt>"
            let payload = String(stored.dropFirst(7))
            guard let colonIdx = payload.firstIndex(of: ":") else { return false }
            let storedHashPart = String(payload[payload.startIndex..<colonIdx])
            let salt = String(payload[payload.index(after: colonIdx)...])
            let verified = pbkdf2Hash(pin: pin, salt: salt) == storedHashPart
            logAuthEvent("pin_verify", userId: user.id, success: verified)
            return verified
        } else {
            // Legacy SHA256 — verify and silently upgrade to PBKDF2
            let legacy = sha256Legacy(pin, userId: user.id)
            if legacy == stored {
                let newStored = hashPIN(pin, userId: user.id)
                KeychainService.set(newStored, for: "pin_\(user.id.uuidString)")
                logAuthEvent("pin_verify_upgraded", userId: user.id, success: true)
                return true
            }
            logAuthEvent("pin_verify", userId: user.id, success: false)
            return false
        }
    }

    func setCurrentUser(_ user: UserProfile) {
        currentUser = user
        KeychainService.set(user.id.uuidString, for: "lastLoggedInUserId")
    }

    /// Call this AFTER PIN is verified to properly sign in to Firebase Auth.
    func signInToFirebase(user: UserProfile, pin: String) {
        Task {
            await FirebaseAuthService.shared.signIn(email: user.email, pin: pin, userId: user.id)
            await syncFromFirestore(for: user)
        }
    }

    func logout() {
        currentUser = nil
        Task { @MainActor in FirebaseAuthService.shared.signOut() }
    }

    func lastLoggedInUser() -> UserProfile? {
        guard let idStr = KeychainService.getString(for: "lastLoggedInUserId"),
              let id = UUID(uuidString: idStr) else { return nil }
        return registeredUsers.first { $0.id == id }
    }

    func household(for user: UserProfile) -> RegisteredHousehold? {
        registeredHouseholds.first { $0.id == user.householdId }
    }

    // MARK: - Firestore Sync

    /// Syncs users and household from Firestore — called after successful PIN login.
    func syncFromFirestore(for user: UserProfile) async {
        // Load all household members
        let members = await FirestoreService.shared.loadHouseholdMembers(householdId: user.householdId)
        await MainActor.run {
            for member in members {
                if let idx = registeredUsers.firstIndex(where: { $0.id == member.id }) {
                    registeredUsers[idx] = member
                } else {
                    registeredUsers.append(member)
                }
            }
        }
        // Load household
        if let hh = await FirestoreService.shared.loadHousehold(id: user.householdId) {
            await MainActor.run {
                if let idx = registeredHouseholds.firstIndex(where: { $0.id == hh.id }) {
                    registeredHouseholds[idx] = hh
                } else {
                    registeredHouseholds.append(hh)
                }
            }
        }
        await MainActor.run { saveUsersToKeychain() }
    }

    // MARK: - Family / Invite

    @discardableResult
    func generateInviteCode(for householdId: UUID) -> String {
        let codeKey  = "invite_household_\(householdId.uuidString)"
        let expiryKey = "invite_expiry_\(householdId.uuidString)"

        // Return existing code if not yet expired
        if let existing = KeychainService.getString(for: codeKey),
           let expiryStr = KeychainService.getString(for: expiryKey),
           let expiryInterval = TimeInterval(expiryStr),
           Date(timeIntervalSince1970: expiryInterval) > Date() {
            return existing
        }

        // Generate 12-char alphanumeric (omit confusable chars: 0, O, 1, I)
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = String((0..<12).map { _ in chars.randomElement()! })
        let expiry = Date().addingTimeInterval(7 * 24 * 3600)   // 7 days

        KeychainService.set(code, for: codeKey)
        KeychainService.set(String(expiry.timeIntervalSince1970), for: expiryKey)
        FirestoreService.shared.saveInviteCode(code, householdId: householdId, expiresAt: expiry)
        return code
    }

    func findHousehold(byCode code: String) -> RegisteredHousehold? {
        // Local lookup first (Keychain)
        if let idStr = KeychainService.getString(for: "invite_code_\(code)"),
           let id = UUID(uuidString: idStr) {
            return registeredHouseholds.first { $0.id == id }
        }
        return nil
    }

    func findHouseholdRemote(byCode code: String) async -> RegisteredHousehold? {
        await FirestoreService.shared.findHousehold(byCode: code)
    }

    func addMember(name: String, username: String, email: String,
                   phoneNumber: String, pin: String,
                   to household: RegisteredHousehold) async -> UserProfile {
        var user = UserProfile(
            name: name,
            username: username.lowercased(),
            email: email.lowercased(),
            phoneNumber: phoneNumber,
            householdId: household.id,
            role: .member,
            avatarColorHex: avatarColor(for: registeredUsers.count)
        )
        if let uid = try? await FirebaseAuthService.shared.createAccount(email: email, pin: pin, userId: user.id) {
            user.firebaseUID = uid
            await FirestoreService.shared.saveAuthLookup(firebaseUID: uid, userId: user.id, householdId: household.id)
        }
        KeychainService.set(hashPIN(pin, userId: user.id), for: "pin_\(user.id.uuidString)")
        registeredUsers.append(user)
        saveUsersToKeychain()
        FirestoreService.shared.saveUser(user)
        return user
    }

    func setBiometricEnabled(for userId: UUID) {
        KeychainService.set("true", for: "biometric_\(userId.uuidString)")
    }

    func joinHousehold(_ household: RegisteredHousehold, userId: UUID) {
        guard let idx = registeredUsers.firstIndex(where: { $0.id == userId }) else { return }
        registeredUsers[idx].householdId = household.id
        registeredUsers[idx].role = .member
        if currentUser?.id == userId { currentUser = registeredUsers[idx] }
        saveUsersToKeychain()
        FirestoreService.shared.saveUser(registeredUsers[idx])
    }

    func householdMembers(for householdId: UUID) -> [UserProfile] {
        registeredUsers.filter { $0.householdId == householdId }
    }

    // MARK: - Role Management

    func updateRole(_ role: UserRole, for userId: UUID) {
        guard let idx = registeredUsers.firstIndex(where: { $0.id == userId }) else { return }
        registeredUsers[idx].role = role
        if currentUser?.id == userId { currentUser = registeredUsers[idx] }
        saveUsersToKeychain()
        FirestoreService.shared.saveUser(registeredUsers[idx])
    }

    func removeMember(_ userId: UUID) {
        guard let member = registeredUsers.first(where: { $0.id == userId }),
              member.role != .owner else { return }
        registeredUsers.removeAll { $0.id == userId }
        KeychainService.delete(for: "pin_\(userId.uuidString)")
        saveUsersToKeychain()
        // Remove from Firestore users collection
        FirestoreService.shared.db.collection("users").document(userId.uuidString).delete()
    }

    // MARK: - Update

    func updateUserName(_ name: String, for userId: UUID) {
        guard let idx = registeredUsers.firstIndex(where: { $0.id == userId }) else { return }
        registeredUsers[idx].name = name
        if currentUser?.id == userId { currentUser = registeredUsers[idx] }
        if let hIdx = registeredHouseholds.firstIndex(where: { $0.ownerUserId == userId }) {
            registeredHouseholds[hIdx].name = "\(name) عائلة"
            FirestoreService.shared.saveHousehold(registeredHouseholds[hIdx])
        }
        saveUsersToKeychain()
        FirestoreService.shared.saveUser(registeredUsers[idx])
    }

    func changePIN(newPIN: String, for userId: UUID) {
        let stored = hashPIN(newPIN, userId: userId)
        KeychainService.set(stored, for: "pin_\(userId.uuidString)")
        logAuthEvent("pin_changed", userId: userId, success: true)
    }

    func deleteUser(_ userId: UUID) {
        registeredUsers.removeAll { $0.id == userId }
        registeredHouseholds.removeAll { $0.ownerUserId == userId }
        KeychainService.delete(for: "pin_\(userId.uuidString)")
        saveUsersToKeychain()
        // Delete from Firestore
        FirestoreService.shared.db.collection("users").document(userId.uuidString).delete()
    }

    // MARK: - Keychain Persistence (local cache)

    private func loadUsersFromKeychain() {
        if let data = KeychainService.getData(for: Self.usersKey),
           let users = try? JSONDecoder().decode([UserProfile].self, from: data) {
            registeredUsers = users
        }
        if let data = KeychainService.getData(for: Self.householdsKey),
           let hh = try? JSONDecoder().decode([RegisteredHousehold].self, from: data) {
            registeredHouseholds = hh
        }
    }

    func saveUsersToKeychain() {
        if let data = try? JSONEncoder().encode(registeredUsers) {
            KeychainService.set(data, for: Self.usersKey)
        }
        if let data = try? JSONEncoder().encode(registeredHouseholds) {
            KeychainService.set(data, for: Self.householdsKey)
        }
    }

    // MARK: - Helpers

    /// Returns a PBKDF2-hashed PIN stored as "pbkdf2:<base64hash>:<base64salt>"
    func hashPIN(_ pin: String, userId: UUID) -> String {
        var saltBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
        let salt = Data(saltBytes).base64EncodedString()
        let hash = pbkdf2Hash(pin: pin, salt: salt)
        return "pbkdf2:\(hash):\(salt)"
    }

    /// PBKDF2-HMAC-SHA256 with 100,000 iterations.
    private func pbkdf2Hash(pin: String, salt: String) -> String {
        guard let saltData = Data(base64Encoded: salt),
              let pinData = pin.data(using: .utf8) else { return "" }
        var derivedKey = [UInt8](repeating: 0, count: 32)
        let rc = pinData.withUnsafeBytes { pinPtr in
            saltData.withUnsafeBytes { saltPtr in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinPtr.baseAddress?.assumingMemoryBound(to: Int8.self), pinData.count,
                    saltPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), saltData.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    100_000,
                    &derivedKey, derivedKey.count
                )
            }
        }
        return rc == kCCSuccess ? Data(derivedKey).base64EncodedString() : ""
    }

    /// Legacy SHA256 hash — used only for migration of existing stored PINs.
    private func sha256Legacy(_ pin: String, userId: UUID) -> String {
        let input = "\(pin)_\(userId.uuidString)_majuta_salt"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Auth Event Logging (S7)
    func logAuthEvent(_ event: String, userId: UUID?, success: Bool = true) {
        var data: [String: Any] = [
            "event": event,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ]
        if let uid = userId { data["userId"] = uid.uuidString }
        FirestoreService.shared.db.collection("authLogs").addDocument(data: data)
    }

    private func avatarColor(for index: Int) -> String {
        let colors = ["#F2AE2E", "#22C55E", "#06B6D4", "#8B5CF6", "#EF4444", "#F27F1B"]
        return colors[index % colors.count]
    }
}
