import Foundation
import SwiftUI

struct TransactionCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var nameArabic: String
    var parentCategory: CategoryGroup
    var type: CategoryType
    var icon: String
    var colorHex: String

    /// Returns the category name in the currently selected app language.
    var displayName: String {
        UserDefaults.standard.string(forKey: "appLanguage") == "en" ? name : nameArabic
    }

    init(
        id: UUID = UUID(),
        name: String,
        nameArabic: String,
        parentCategory: CategoryGroup,
        type: CategoryType,
        icon: String,
        colorHex: String = "#6B7280"
    ) {
        self.id = id
        self.name = name
        self.nameArabic = nameArabic
        self.parentCategory = parentCategory
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
    }
}

enum CategoryType: String, Codable {
    case income     = "income"
    case expense    = "expense"
    case savings    = "savings"
    case investment = "investment"
}

enum CategoryGroup: String, Codable, CaseIterable {
    case income    = "income"
    case essential = "essential"
    case lifestyle = "lifestyle"
    case family    = "family"
    case financial = "financial"

    var displayName: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .income:    return isEn ? "Income"             : "الدخل"
        case .essential: return isEn ? "Essential Expenses" : "المصاريف الأساسية"
        case .lifestyle: return isEn ? "Lifestyle"          : "نمط الحياة"
        case .family:    return isEn ? "Family"             : "العائلة"
        case .financial: return isEn ? "Financial"          : "المالية"
        }
    }
}

// MARK: - Default Categories
extension TransactionCategory {
    static let defaultCategories: [TransactionCategory] = [
        // Income
        TransactionCategory(name: "Salary", nameArabic: "الراتب", parentCategory: .income, type: .income, icon: CategoryIcon.salary, colorHex: "#22C55E"),
        TransactionCategory(name: "Side Income", nameArabic: "دخل إضافي", parentCategory: .income, type: .income, icon: CategoryIcon.sideIncome, colorHex: "#16A34A"),
        TransactionCategory(name: "Rental Income", nameArabic: "دخل إيجار", parentCategory: .income, type: .income, icon: CategoryIcon.rentalIncome, colorHex: "#15803D"),
        TransactionCategory(name: "Dividends", nameArabic: "أرباح", parentCategory: .income, type: .income, icon: CategoryIcon.dividends, colorHex: "#166534"),
        TransactionCategory(name: "Refunds", nameArabic: "استرداد", parentCategory: .income, type: .income, icon: CategoryIcon.refunds, colorHex: "#4ADE80"),

        // Essential
        TransactionCategory(name: "Rent", nameArabic: "الإيجار", parentCategory: .essential, type: .expense, icon: CategoryIcon.rent, colorHex: "#0C2031"),
        TransactionCategory(name: "Utilities", nameArabic: "المرافق", parentCategory: .essential, type: .expense, icon: CategoryIcon.utilities, colorHex: "#F2AE2E"),
        TransactionCategory(name: "Groceries", nameArabic: "البقالة", parentCategory: .essential, type: .expense, icon: CategoryIcon.groceries, colorHex: "#F27F1B"),
        TransactionCategory(name: "Fuel", nameArabic: "الوقود", parentCategory: .essential, type: .expense, icon: CategoryIcon.fuel, colorHex: "#DC2626"),
        TransactionCategory(name: "Telecom", nameArabic: "الاتصالات", parentCategory: .essential, type: .expense, icon: CategoryIcon.telecom, colorHex: "#7C3AED"),
        TransactionCategory(name: "Healthcare", nameArabic: "الصحة", parentCategory: .essential, type: .expense, icon: CategoryIcon.healthcare, colorHex: "#EF4444"),
        TransactionCategory(name: "Insurance", nameArabic: "التأمين", parentCategory: .essential, type: .expense, icon: CategoryIcon.insurance, colorHex: "#2563EB"),
        TransactionCategory(name: "Education", nameArabic: "التعليم", parentCategory: .essential, type: .expense, icon: CategoryIcon.education, colorHex: "#0891B2"),
        TransactionCategory(name: "Domestic Worker", nameArabic: "العمالة المنزلية", parentCategory: .essential, type: .expense, icon: CategoryIcon.domesticWorker, colorHex: "#6B7280"),
        TransactionCategory(name: "Loan Installments", nameArabic: "أقساط القروض", parentCategory: .essential, type: .expense, icon: CategoryIcon.loans, colorHex: "#92400E"),

        // Lifestyle
        TransactionCategory(name: "Restaurants", nameArabic: "المطاعم", parentCategory: .lifestyle, type: .expense, icon: CategoryIcon.restaurants, colorHex: "#F59E0B"),
        TransactionCategory(name: "Shopping", nameArabic: "التسوق", parentCategory: .lifestyle, type: .expense, icon: CategoryIcon.shopping, colorHex: "#EC4899"),
        TransactionCategory(name: "Entertainment", nameArabic: "الترفيه", parentCategory: .lifestyle, type: .expense, icon: CategoryIcon.entertainment, colorHex: "#8B5CF6"),
        TransactionCategory(name: "Travel", nameArabic: "السفر", parentCategory: .lifestyle, type: .expense, icon: CategoryIcon.travel, colorHex: "#06B6D4"),
        TransactionCategory(name: "Fitness", nameArabic: "الرياضة", parentCategory: .lifestyle, type: .expense, icon: CategoryIcon.fitness, colorHex: "#10B981"),

        // Family
        TransactionCategory(name: "Kids", nameArabic: "الأطفال", parentCategory: .family, type: .expense, icon: CategoryIcon.kids, colorHex: "#F472B6"),
        TransactionCategory(name: "Parents Support", nameArabic: "دعم الوالدين", parentCategory: .family, type: .expense, icon: CategoryIcon.parentsSupport, colorHex: "#FB7185"),
        TransactionCategory(name: "Gifts", nameArabic: "الهدايا", parentCategory: .family, type: .expense, icon: CategoryIcon.gifts, colorHex: "#A78BFA"),

        // Financial
        TransactionCategory(name: "Savings", nameArabic: "المدخرات", parentCategory: .financial, type: .savings, icon: CategoryIcon.savings, colorHex: "#22C55E"),
        TransactionCategory(name: "Investments", nameArabic: "الاستثمارات", parentCategory: .financial, type: .investment, icon: CategoryIcon.investments, colorHex: "#F2AE2E"),
        TransactionCategory(name: "Emergency Fund", nameArabic: "صندوق الطوارئ", parentCategory: .financial, type: .savings, icon: CategoryIcon.emergencyFund, colorHex: "#EF4444"),
        TransactionCategory(name: "Debt Repayment", nameArabic: "سداد الديون", parentCategory: .financial, type: .expense, icon: CategoryIcon.debtRepayment, colorHex: "#6B7280"),
    ]
}
