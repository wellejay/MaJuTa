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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isGuestMode {
                    // Guest user: show onboarding if not done, otherwise main app
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
                } else if userService.registeredUsers.isEmpty && !authService.showRegistration {
                    // No registered users yet — show welcome gate (satisfies Apple Guideline 5.1.1v)
                    WelcomeGateView()
                        .environmentObject(appState)
                        .environmentObject(authService)
                } else if authService.showRegistration {
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
            // S5: Privacy screen — blur financial content in App Switcher and when app is inactive
            .overlay {
                if scenePhase != .active {
                    ZStack {
                        Color.black.opacity(0.85)
                        VStack(spacing: 16) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.6))
                            Text("MaJuTa")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                            Text("محتوى مالي محمي")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(appState.colorScheme)
            .task { appState.loadProfileImage() }
            // Handle majuta://email-verified deep link
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

// MARK: - Welcome Gate (Apple Guideline 5.1.1v)

struct WelcomeGateView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            Color.maJuTaBackground.ignoresSafeArea()

            VStack(spacing: MaJuTaSpacing.xl) {
                Spacer()

                // Logo / Branding
                VStack(spacing: MaJuTaSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.maJuTaGold.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.maJuTaGold)
                    }
                    Text("MaJuTa")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("مدير ميزانيتك الشخصية")
                        .font(.maJuTaBody)
                        .foregroundColor(.maJuTaTextSecondary)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: MaJuTaSpacing.md) {
                    // Primary: Create Account
                    Button {
                        authService.showRegistration = true
                    } label: {
                        Text("إنشاء حساب جديد")
                            .font(.maJuTaBodyBold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MaJuTaSpacing.md)
                            .background(Color.maJuTaGold)
                            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }

                    // Secondary: Browse as Guest
                    Button {
                        UserService.shared.setupGuestUser()
                        DataStore.shared.loadGuestMode()
                        appState.isGuestMode = true
                    } label: {
                        Text("تصفح كضيف — بدون حساب")
                            .font(.maJuTaBody)
                            .foregroundColor(.maJuTaTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MaJuTaSpacing.md)
                            .background(Color.maJuTaCard)
                            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Text("بياناتك في وضع الضيف تُحفظ على جهازك فقط")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Spacer().frame(height: MaJuTaSpacing.xl)
            }
        }
    }
}
