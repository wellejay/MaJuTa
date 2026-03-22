import Foundation
import FirebaseFirestore
import OSLog

private let logger = Logger(subsystem: "com.majuta.app", category: "firestore")

final class FirestoreService {
    static let shared = FirestoreService()
    let db: Firestore

    private init() {
        db = Firestore.firestore()
        // Offline persistence is enabled by default on iOS
    }

    // MARK: - Path Helpers
    func householdRef(_ householdId: UUID) -> DocumentReference {
        db.collection("households").document(householdId.uuidString)
    }

    func collection(_ name: String, householdId: UUID) -> CollectionReference {
        householdRef(householdId).collection(name)
    }

    // MARK: - Users
    func saveUser(_ user: UserProfile) {
        do {
            try db.collection("users").document(user.id.uuidString).setData(from: user, merge: true)
        } catch { logger.error("saveUser failed: \(error.localizedDescription, privacy: .private)") }
    }

    func loadUser(id: UUID) async -> UserProfile? {
        try? await db.collection("users").document(id.uuidString).getDocument(as: UserProfile.self)
    }

    func loadHouseholdMembers(householdId: UUID) async -> [UserProfile] {
        guard let snap = try? await db.collection("users")
            .whereField("householdId", isEqualTo: householdId.uuidString)
            .getDocuments() else { return [] }
        return snap.documents.compactMap { try? $0.data(as: UserProfile.self) }
    }

    // MARK: - Households
    func saveHousehold(_ household: RegisteredHousehold) {
        do {
            try db.collection("households").document(household.id.uuidString).setData(from: household, merge: true)
        } catch { logger.error("saveHousehold failed: \(error.localizedDescription, privacy: .private)") }
    }

    func loadHousehold(id: UUID) async -> RegisteredHousehold? {
        try? await db.collection("households").document(id.uuidString).getDocument(as: RegisteredHousehold.self)
    }

    // MARK: - Auth Lookup (Firebase UID → householdId, for security rules)
    /// Async version — awaits Firestore confirmation so that subsequent writes and
    /// listener setups are guaranteed to see the authLookup entry when rules evaluate.
    func saveAuthLookup(firebaseUID: String, userId: UUID, householdId: UUID) async {
        try? await db.collection("authLookup").document(firebaseUID).setData([
            "userId": userId.uuidString,
            "householdId": householdId.uuidString
        ], merge: true)
    }

    // MARK: - Invite Codes
    func saveInviteCode(_ code: String, householdId: UUID, expiresAt: Date? = nil) {
        var data: [String: Any] = [
            "householdId": householdId.uuidString,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let expiry = expiresAt {
            data["expiresAt"] = Timestamp(date: expiry)
        }
        db.collection("inviteCodes").document(code).setData(data, merge: true)
    }

    func findHousehold(byCode code: String) async -> RegisteredHousehold? {
        guard let doc = try? await db.collection("inviteCodes").document(code).getDocument(),
              doc.exists,
              let idStr = doc.data()?["householdId"] as? String,
              let id = UUID(uuidString: idStr) else { return nil }
        // S2: Check expiry
        if let expiresAt = (doc.data()?["expiresAt"] as? Timestamp)?.dateValue(),
           expiresAt < Date() {
            return nil   // Code expired
        }
        return await loadHousehold(id: id)
    }

    // MARK: - Username Uniqueness (S6)
    func isUsernameAvailable(_ username: String) async -> Bool {
        let lower = username.lowercased()
        let snap = try? await db.collection("users")
            .whereField("username", isEqualTo: lower)
            .limit(to: 1)
            .getDocuments()
        return snap?.documents.isEmpty ?? true
    }

    // MARK: - Generic Collection Operations
    func save<T: Encodable & Identifiable>(_ item: T, to collectionName: String, householdId: UUID) where T.ID == UUID {
        do {
            try collection(collectionName, householdId: householdId)
                .document(item.id.uuidString)
                .setData(from: item)
        } catch { logger.error("save \(collectionName) failed: \(error.localizedDescription, privacy: .private)") }
    }

    func delete(id: UUID, from collectionName: String, householdId: UUID) {
        collection(collectionName, householdId: householdId).document(id.uuidString).delete()
    }

    /// Atomically increments a numeric field in a Firestore document.
    /// Safe for concurrent offline edits — Firestore resolves deltas server-side.
    func incrementField(_ field: String, by delta: Double,
                        in collectionName: String, documentId: String,
                        householdId: UUID) {
        let ref = collection(collectionName, householdId: householdId)
            .document(documentId)
        ref.updateData([field: FieldValue.increment(delta)])
    }

    func listen<T: Decodable>(
        collection collectionName: String,
        householdId: UUID,
        onChange: @escaping @MainActor ([T]) -> Void
    ) -> ListenerRegistration {
        collection(collectionName, householdId: householdId)
            .addSnapshotListener { snapshot, error in
                if let error { logger.error("listener \(collectionName) error: \(error.localizedDescription, privacy: .private)"); return }
                let items = snapshot?.documents.compactMap { try? $0.data(as: T.self) } ?? []
                Task { @MainActor in onChange(items) }
            }
    }
}
