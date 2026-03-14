import Foundation

struct Household: Identifiable, Codable {
    let id: UUID
    var name: String
    var ownerUserId: UUID
    var members: [HouseholdMember]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        ownerUserId: UUID,
        members: [HouseholdMember] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.ownerUserId = ownerUserId
        self.members = members
        self.createdAt = createdAt
    }
}

struct HouseholdMember: Identifiable, Codable {
    let id: UUID
    var householdId: UUID
    var userId: UUID
    var role: HouseholdRole
    var permissions: MemberPermissions
    var createdAt: Date

    init(
        id: UUID = UUID(),
        householdId: UUID,
        userId: UUID,
        role: HouseholdRole,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.userId = userId
        self.role = role
        self.permissions = role.defaultPermissions
        self.createdAt = createdAt
    }
}

enum HouseholdRole: String, Codable, CaseIterable {
    case owner    = "owner"
    case admin    = "admin"
    case member   = "member"
    case viewOnly = "view_only"

    var displayName: String {
        switch self {
        case .owner:    return "المالك"
        case .admin:    return "مدير"
        case .member:   return "عضو"
        case .viewOnly: return "عرض فقط"
        }
    }

    var defaultPermissions: MemberPermissions {
        switch self {
        case .owner:
            return MemberPermissions(
                viewSharedAccounts: true, editSharedAccounts: true,
                createTransactions: true, viewReports: true,
                inviteMembers: true, removeMembers: true,
                changePermissions: true
            )
        case .admin:
            return MemberPermissions(
                viewSharedAccounts: true, editSharedAccounts: true,
                createTransactions: true, viewReports: true,
                inviteMembers: true, removeMembers: false,
                changePermissions: false
            )
        case .member:
            return MemberPermissions(
                viewSharedAccounts: true, editSharedAccounts: false,
                createTransactions: true, viewReports: true,
                inviteMembers: false, removeMembers: false,
                changePermissions: false
            )
        case .viewOnly:
            return MemberPermissions(
                viewSharedAccounts: true, editSharedAccounts: false,
                createTransactions: false, viewReports: true,
                inviteMembers: false, removeMembers: false,
                changePermissions: false
            )
        }
    }
}

struct MemberPermissions: Codable {
    var viewSharedAccounts: Bool
    var editSharedAccounts: Bool
    var createTransactions: Bool
    var viewReports: Bool
    var inviteMembers: Bool
    var removeMembers: Bool
    var changePermissions: Bool
}

struct HouseholdInvitation: Identifiable, Codable {
    let id: UUID
    var householdId: UUID
    var email: String
    var role: HouseholdRole
    var status: InvitationStatus
    var createdAt: Date

    enum InvitationStatus: String, Codable {
        case pending  = "pending"
        case accepted = "accepted"
        case expired  = "expired"
    }
}

struct ActivityLog: Identifiable, Codable {
    let id: UUID
    var householdId: UUID
    var userId: UUID
    var actionType: ActivityAction
    var objectType: String
    var objectId: UUID
    var timestamp: Date

    enum ActivityAction: String, Codable {
        case transactionCreated = "transaction_created"
        case transactionDeleted = "transaction_deleted"
        case memberAdded        = "member_added"
        case memberRemoved      = "member_removed"
        case accountCreated     = "account_created"
        case goalUpdated        = "goal_updated"
    }
}
