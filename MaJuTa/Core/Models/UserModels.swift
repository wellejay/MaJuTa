import Foundation

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable {
    case owner    = "owner"
    case admin    = "admin"
    case member   = "member"
    case viewOnly = "view_only"

    var displayName: String {
        switch self {
        case .owner:    return "المالك"
        case .admin:    return "مدير"
        case .member:   return "عضو"
        case .viewOnly: return "مشاهد فقط"
        }
    }

    // MARK: - Permissions
    var canViewSharedAccounts: Bool  { true }
    var canEditSharedAccounts: Bool  { self == .owner || self == .admin }
    var canAddTransactions: Bool     { self == .owner || self == .admin || self == .member }
    var canInviteMembers: Bool       { self == .owner || self == .admin }
    var canRemoveMembers: Bool       { self == .owner }
    var canChangePermissions: Bool   { self == .owner }
    var canDeleteHousehold: Bool     { self == .owner }
}

// MARK: - User Profile
struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var username: String       // unique @handle
    var email: String
    var phoneNumber: String
    var householdId: UUID
    var role: UserRole
    let createdAt: Date
    var avatarColorHex: String
    var firebaseUID: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, username, email, phoneNumber, householdId, role, createdAt, avatarColorHex, firebaseUID
    }

    init(id: UUID = UUID(), name: String, username: String = "",
         email: String = "", phoneNumber: String = "",
         householdId: UUID, role: UserRole = .owner,
         avatarColorHex: String = "#F2AE2E",
         firebaseUID: String? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.householdId = householdId
        self.role = role
        self.createdAt = Date()
        self.avatarColorHex = avatarColorHex
        self.firebaseUID = firebaseUID
    }

    // Backward-compatible decoder — new fields default to "" / nil if missing
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,     forKey: .id)
        name        = try c.decode(String.self,   forKey: .name)
        username    = try c.decodeIfPresent(String.self, forKey: .username)    ?? ""
        email       = try c.decodeIfPresent(String.self, forKey: .email)       ?? ""
        phoneNumber = try c.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        householdId = try c.decode(UUID.self,     forKey: .householdId)
        role        = try c.decode(UserRole.self, forKey: .role)
        createdAt   = try c.decode(Date.self,     forKey: .createdAt)
        avatarColorHex = try c.decode(String.self, forKey: .avatarColorHex)
        firebaseUID = try c.decodeIfPresent(String.self, forKey: .firebaseUID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,             forKey: .id)
        try c.encode(name,           forKey: .name)
        try c.encode(username,       forKey: .username)
        try c.encode(email,          forKey: .email)
        try c.encode(phoneNumber,    forKey: .phoneNumber)
        try c.encode(householdId,    forKey: .householdId)
        try c.encode(role,           forKey: .role)
        try c.encode(createdAt,      forKey: .createdAt)
        try c.encode(avatarColorHex, forKey: .avatarColorHex)
        try c.encodeIfPresent(firebaseUID, forKey: .firebaseUID)
    }
}

// MARK: - Registered Household
struct RegisteredHousehold: Codable, Identifiable {
    let id: UUID
    var name: String
    let ownerUserId: UUID
    let createdAt: Date

    init(id: UUID = UUID(), name: String, ownerUserId: UUID) {
        self.id = id
        self.name = name
        self.ownerUserId = ownerUserId
        self.createdAt = Date()
    }
}

// MARK: - Household Member (for Phase 2 multi-user)
struct HouseholdMembership: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    var role: UserRole
    let joinedAt: Date

    init(householdId: UUID, userId: UUID, role: UserRole) {
        self.id = UUID()
        self.householdId = householdId
        self.userId = userId
        self.role = role
        self.joinedAt = Date()
    }
}

// MARK: - Activity Log Entry
struct ActivityEntry: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let userName: String
    let actionType: ActivityActionType
    let objectType: String
    let objectDescription: String
    let timestamp: Date

    init(householdId: UUID, userId: UUID, userName: String,
         actionType: ActivityActionType, objectType: String, objectDescription: String) {
        self.id = UUID()
        self.householdId = householdId
        self.userId = userId
        self.userName = userName
        self.actionType = actionType
        self.objectType = objectType
        self.objectDescription = objectDescription
        self.timestamp = Date()
    }
}

enum ActivityActionType: String, Codable {
    case transactionCreated  = "transaction_created"
    case transactionDeleted  = "transaction_deleted"
    case accountCreated      = "account_created"
    case goalUpdated         = "goal_updated"
    case goalCreated         = "goal_created"
    case billCreated         = "bill_created"
    case memberAdded         = "member_added"
    case memberRemoved       = "member_removed"
    case pinChanged          = "pin_changed"

    var arabicDescription: String {
        switch self {
        case .transactionCreated:  return "أضاف معاملة"
        case .transactionDeleted:  return "حذف معاملة"
        case .accountCreated:      return "أنشأ حساباً"
        case .goalUpdated:         return "حدّث هدفاً"
        case .goalCreated:         return "أنشأ هدفاً"
        case .billCreated:         return "أضاف فاتورة"
        case .memberAdded:         return "أضاف عضواً"
        case .memberRemoved:       return "أزال عضواً"
        case .pinChanged:          return "غيّر الرمز السري"
        }
    }
}

// MARK: - Invitation (Phase 2)
struct UserInvitation: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let email: String
    let role: UserRole
    var status: InvitationStatus
    let createdAt: Date

    enum InvitationStatus: String, Codable {
        case pending, accepted, expired
    }
}
