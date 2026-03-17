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

// MARK: - Country Phone Code

struct CountryPhoneCode: Identifiable, Hashable {
    let id: String          // ISO 3166-1 alpha-2
    let name: String        // Arabic display name
    let dialCode: String    // e.g., "+1"
    let placeholder: String // local number format using X for each digit
    let digitCount: Int     // expected local digit count

    var flag: String {
        id.unicodeScalars.reduce("") { $0 + String(UnicodeScalar(127397 + $1.value)!) }
    }

    /// Formats a string of digits using the given pattern (X = digit, other chars = separator).
    static func formatPhoneNumber(_ digits: String, pattern: String) -> String {
        var result = ""
        var dIdx = digits.startIndex
        for char in pattern {
            guard dIdx < digits.endIndex else { break }
            if char == "X" {
                result.append(digits[dIdx])
                dIdx = digits.index(after: dIdx)
            } else {
                result.append(char)
            }
        }
        return result
    }

    static let defaultCountry = CountryPhoneCode(
        id: "SA", name: "المملكة العربية السعودية", dialCode: "+966", placeholder: "XX XXX XXXX", digitCount: 9
    )

    static let all: [CountryPhoneCode] = [
        // Arabian Peninsula
        CountryPhoneCode(id: "SA", name: "المملكة العربية السعودية", dialCode: "+966", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "AE", name: "الإمارات العربية المتحدة", dialCode: "+971", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "KW", name: "الكويت",                   dialCode: "+965", placeholder: "XXXX XXXX",   digitCount: 8),
        CountryPhoneCode(id: "QA", name: "قطر",                      dialCode: "+974", placeholder: "XXXX XXXX",   digitCount: 8),
        CountryPhoneCode(id: "BH", name: "البحرين",                  dialCode: "+973", placeholder: "XXXX XXXX",   digitCount: 8),
        CountryPhoneCode(id: "OM", name: "عُمان",                    dialCode: "+968", placeholder: "XXXX XXXX",   digitCount: 8),
        // Levant & Arab World
        CountryPhoneCode(id: "JO", name: "الأردن",                   dialCode: "+962", placeholder: "X XXXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "LB", name: "لبنان",                    dialCode: "+961", placeholder: "XX XXX XXX",  digitCount: 8),
        CountryPhoneCode(id: "EG", name: "مصر",                      dialCode: "+20",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "IQ", name: "العراق",                   dialCode: "+964", placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "SY", name: "سوريا",                    dialCode: "+963", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "YE", name: "اليمن",                    dialCode: "+967", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "PS", name: "فلسطين",                   dialCode: "+970", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "LY", name: "ليبيا",                    dialCode: "+218", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "TN", name: "تونس",                     dialCode: "+216", placeholder: "XX XXX XXX",  digitCount: 8),
        CountryPhoneCode(id: "DZ", name: "الجزائر",                  dialCode: "+213", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "MA", name: "المغرب",                   dialCode: "+212", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "SD", name: "السودان",                  dialCode: "+249", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "SO", name: "الصومال",                  dialCode: "+252", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "MR", name: "موريتانيا",                dialCode: "+222", placeholder: "XX XX XXXX",  digitCount: 8),
        // Americas
        CountryPhoneCode(id: "US", name: "الولايات المتحدة",         dialCode: "+1",   placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "CA", name: "كندا",                     dialCode: "+1",   placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "MX", name: "المكسيك",                  dialCode: "+52",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "BR", name: "البرازيل",                 dialCode: "+55",  placeholder: "XX XXXXX XXXX",digitCount: 11),
        CountryPhoneCode(id: "AR", name: "الأرجنتين",                dialCode: "+54",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "CO", name: "كولومبيا",                 dialCode: "+57",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "CL", name: "تشيلي",                    dialCode: "+56",  placeholder: "X XXXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "PE", name: "بيرو",                     dialCode: "+51",  placeholder: "XXX XXX XXX", digitCount: 9),
        // Europe
        CountryPhoneCode(id: "GB", name: "المملكة المتحدة",          dialCode: "+44",  placeholder: "XXXX XXXXXX", digitCount: 10),
        CountryPhoneCode(id: "DE", name: "ألمانيا",                  dialCode: "+49",  placeholder: "XXX XXXXXXX", digitCount: 10),
        CountryPhoneCode(id: "FR", name: "فرنسا",                    dialCode: "+33",  placeholder: "X XX XX XX XX",digitCount: 9),
        CountryPhoneCode(id: "IT", name: "إيطاليا",                  dialCode: "+39",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "ES", name: "إسبانيا",                  dialCode: "+34",  placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "NL", name: "هولندا",                   dialCode: "+31",  placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "BE", name: "بلجيكا",                   dialCode: "+32",  placeholder: "XXX XX XX XX",digitCount: 9),
        CountryPhoneCode(id: "CH", name: "سويسرا",                   dialCode: "+41",  placeholder: "XX XXX XX XX",digitCount: 9),
        CountryPhoneCode(id: "AT", name: "النمسا",                   dialCode: "+43",  placeholder: "XXX XXXXXXX", digitCount: 10),
        CountryPhoneCode(id: "SE", name: "السويد",                   dialCode: "+46",  placeholder: "XX XXX XX XX",digitCount: 9),
        CountryPhoneCode(id: "NO", name: "النرويج",                  dialCode: "+47",  placeholder: "XXX XX XXX",  digitCount: 8),
        CountryPhoneCode(id: "DK", name: "الدنمارك",                 dialCode: "+45",  placeholder: "XXXX XXXX",   digitCount: 8),
        CountryPhoneCode(id: "FI", name: "فنلندا",                   dialCode: "+358", placeholder: "XX XXXXXXX",  digitCount: 9),
        CountryPhoneCode(id: "PL", name: "بولندا",                   dialCode: "+48",  placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "PT", name: "البرتغال",                 dialCode: "+351", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "GR", name: "اليونان",                  dialCode: "+30",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "TR", name: "تركيا",                    dialCode: "+90",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "RU", name: "روسيا",                    dialCode: "+7",   placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "UA", name: "أوكرانيا",                 dialCode: "+380", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "RO", name: "رومانيا",                  dialCode: "+40",  placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "CZ", name: "التشيك",                   dialCode: "+420", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "HU", name: "المجر",                    dialCode: "+36",  placeholder: "XX XXX XXXX", digitCount: 9),
        // Asia
        CountryPhoneCode(id: "IN", name: "الهند",                    dialCode: "+91",  placeholder: "XXXXX XXXXX", digitCount: 10),
        CountryPhoneCode(id: "CN", name: "الصين",                    dialCode: "+86",  placeholder: "XXX XXXX XXXX",digitCount: 11),
        CountryPhoneCode(id: "JP", name: "اليابان",                  dialCode: "+81",  placeholder: "XX XXXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "KR", name: "كوريا الجنوبية",           dialCode: "+82",  placeholder: "XX XXXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "PK", name: "باكستان",                  dialCode: "+92",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "BD", name: "بنغلاديش",                 dialCode: "+880", placeholder: "XXXX XXXXXX", digitCount: 10),
        CountryPhoneCode(id: "ID", name: "إندونيسيا",                dialCode: "+62",  placeholder: "XXX XXXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "MY", name: "ماليزيا",                  dialCode: "+60",  placeholder: "XX XXXX XXXX",digitCount: 9),
        CountryPhoneCode(id: "SG", name: "سنغافورة",                 dialCode: "+65",  placeholder: "XXXX XXXX",   digitCount: 8),
        CountryPhoneCode(id: "TH", name: "تايلاند",                  dialCode: "+66",  placeholder: "X XXXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "PH", name: "الفلبين",                  dialCode: "+63",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "VN", name: "فيتنام",                   dialCode: "+84",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "AF", name: "أفغانستان",                dialCode: "+93",  placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "IR", name: "إيران",                    dialCode: "+98",  placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "UZ", name: "أوزبكستان",                dialCode: "+998", placeholder: "XX XXX XXXX", digitCount: 9),
        // Africa
        CountryPhoneCode(id: "NG", name: "نيجيريا",                  dialCode: "+234", placeholder: "XXX XXX XXXX",digitCount: 10),
        CountryPhoneCode(id: "ZA", name: "جنوب أفريقيا",             dialCode: "+27",  placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "KE", name: "كينيا",                    dialCode: "+254", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "ET", name: "إثيوبيا",                  dialCode: "+251", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "GH", name: "غانا",                     dialCode: "+233", placeholder: "XX XXX XXXX", digitCount: 9),
        CountryPhoneCode(id: "TZ", name: "تنزانيا",                  dialCode: "+255", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "UG", name: "أوغندا",                   dialCode: "+256", placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "SN", name: "السنغال",                  dialCode: "+221", placeholder: "XX XXX XXXX", digitCount: 9),
        // Oceania
        CountryPhoneCode(id: "AU", name: "أستراليا",                 dialCode: "+61",  placeholder: "XXX XXX XXX", digitCount: 9),
        CountryPhoneCode(id: "NZ", name: "نيوزيلندا",                dialCode: "+64",  placeholder: "XX XXX XXXX", digitCount: 9),
    ]

    static func search(_ query: String) -> [CountryPhoneCode] {
        let list = all.sorted { $0.name < $1.name }
        guard !query.isEmpty else { return list }
        let q = query.lowercased()
        return list.filter {
            $0.name.contains(query) || $0.dialCode.contains(q) || $0.id.lowercased().contains(q)
        }
    }
}
