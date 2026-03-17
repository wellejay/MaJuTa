import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("preferredColorScheme") private var storedColorScheme: String = "system"
    @AppStorage("isGuestMode") var isGuestMode: Bool = false
    @AppStorage("appLanguage") var appLanguage: String = "ar"

    var layoutDirection: LayoutDirection { appLanguage == "ar" ? .rightToLeft : .leftToRight }

    // MARK: - Current User (delegates to UserService)
    var currentUser: UserProfile? { UserService.shared.currentUser }

    var userName: String {
        get { currentUser?.name ?? "" }
        set {
            guard let userId = currentUser?.id else { return }
            UserService.shared.updateUserName(newValue, for: userId)
            objectWillChange.send()
        }
    }

    // MARK: - Profile Image (stored encrypted in Documents)
    @Published var profileImage: UIImage? = nil

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
    }

    func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: Self.profileImageURL, options: [.atomic, .completeFileProtection])
        DispatchQueue.main.async { self.profileImage = image }
    }

    func loadProfileImage() {
        guard let data = try? Data(contentsOf: Self.profileImageURL),
              let image = UIImage(data: data) else { return }
        profileImage = image
    }

    func deleteProfileImage() {
        try? FileManager.default.removeItem(at: Self.profileImageURL)
        profileImage = nil
    }

    // Monthly income is sensitive — stored in Keychain, NOT UserDefaults
    var monthlyIncome: Double {
        get { KeychainService.getDouble(for: "monthlyIncome") ?? 0 }
        set { KeychainService.set(newValue, for: "monthlyIncome"); objectWillChange.send() }
    }

    // User-defined monthly spending limit for the safeToSpend card
    var spendingLimit: Double {
        get { KeychainService.getDouble(for: "spendingLimit") ?? 0 }
        set { KeychainService.set(newValue, for: "spendingLimit"); objectWillChange.send() }
    }

    @Published var selectedTab: AppTab = .dashboard
    @Published var showAddTransaction: Bool = false

    var colorScheme: ColorScheme? {
        switch storedColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func setColorScheme(_ scheme: ColorScheme?) {
        switch scheme {
        case .light: storedColorScheme = "light"
        case .dark: storedColorScheme = "dark"
        default: storedColorScheme = "system"
        }
    }

    func resetAll() {
        // Exit guest mode cleanly
        if isGuestMode {
            isGuestMode = false
            DataStore.shared.isGuestMode = false
            UserService.shared.clearGuestUser()
            hasCompletedOnboarding = false
            KeychainService.delete(for: "monthlyIncome")
            KeychainService.delete(for: "spendingLimit")
            deleteProfileImage()
            DataStore.shared.clearAll()
            objectWillChange.send()
            return
        }
        hasCompletedOnboarding = false
        KeychainService.delete(for: "monthlyIncome")
        KeychainService.delete(for: "spendingLimit")
        KeychainService.delete(for: "lastLoggedInUserId")
        deleteProfileImage()
        UserService.shared.logout()
        Task { @MainActor in
            DataStore.shared.loadForCurrentUser()
        }
        objectWillChange.send()
    }
}

enum AppTab: String, CaseIterable {
    case dashboard    = "dashboard"
    case transactions = "transactions"
    case goals        = "goals"
    case investments  = "investments"
    case loans        = "loans"
    case family       = "family"
    case profile      = "profile"

    var title: String {
        switch self {
        case .dashboard:    return "الرئيسية"
        case .transactions: return "المعاملات"
        case .goals:        return "الأهداف"
        case .investments:  return "الاستثمارات"
        case .loans:        return "القروض"
        case .family:       return "العائلة"
        case .profile:      return "الحساب"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:    return "house.fill"
        case .transactions: return "arrow.left.arrow.right"
        case .goals:        return "target"
        case .investments:  return "chart.line.uptrend.xyaxis"
        case .loans:        return "creditcard.fill"
        case .family:       return "person.2.fill"
        case .profile:      return "person.fill"
        }
    }
}
