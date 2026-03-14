import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var language: AppLanguage
    var currency: String
    var country: String
    var householdId: UUID
    var monthlyIncome: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        language: AppLanguage = .arabic,
        currency: String = "SAR",
        country: String = "SA",
        householdId: UUID = UUID(),
        monthlyIncome: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.language = language
        self.currency = currency
        self.country = country
        self.householdId = householdId
        self.monthlyIncome = monthlyIncome
        self.createdAt = createdAt
    }
}

enum AppLanguage: String, Codable, CaseIterable {
    case arabic  = "ar"
    case english = "en"

    var displayName: String {
        switch self {
        case .arabic:  return "العربية"
        case .english: return "English"
        }
    }
}
