import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MaJuTaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthenticationService()
    @ObservedObject private var userService = UserService.shared
    var body: some Scene {
        WindowGroup {
            Group {
                if userService.registeredUsers.isEmpty || authService.showRegistration {
                    RegistrationView()
                        .environmentObject(authService)
                } else if authService.showEmailVerification {
                    EmailVerificationView()
                        .environmentObject(authService)
                } else if !authService.isAuthenticated {
                    UserPickerView()
                        .environmentObject(authService)
                } else if userService.currentUser != nil {
                    if appState.hasCompletedOnboarding {
                        MainTabView()
                            .environmentObject(appState)
                            .environmentObject(authService)
                            .environmentObject(DataStore.shared)
                    } else {
                        OnboardingView()
                            .environmentObject(appState)
                            .environmentObject(authService)
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(appState.colorScheme)
            .task { appState.loadProfileImage() }
            // Handle majuta://email-verified deep link sent from the Firebase Hosting
            // redirect page after the user taps the verification link in their email.
            .onOpenURL { url in
                guard url.scheme == "majuta",
                      url.host == "email-verified" else { return }
                Task {
                    await FirebaseAuthService.shared.handleEmailVerifiedDeepLink()
                    if FirebaseAuthService.shared.isEmailVerified {
                        authService.showEmailVerification = false
                        authService.isAuthenticated = true
                    }
                }
            }
        }
    }
}
