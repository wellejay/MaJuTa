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
                        .environmentObject(appState)
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
            .environment(\.layoutDirection, appState.layoutDirection)
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
    @State private var showLanguagePicker = false

    var body: some View {
        ZStack {
            Color.maJuTaBackground.ignoresSafeArea()

            VStack(spacing: MaJuTaSpacing.xl) {

                // Language button — top trailing
                HStack {
                    Spacer()
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                            Text("Language / اللغة")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.maJuTaTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.maJuTaCard)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.top, MaJuTaSpacing.sm)

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
                    Text("Your Personal Budget Manager")
                        .font(.system(size: 13))
                        .foregroundColor(.maJuTaTextSecondary.opacity(0.6))
                }

                Spacer()

                // Action Buttons
                VStack(spacing: MaJuTaSpacing.md) {
                    // Primary: Create Account
                    Button {
                        authService.showRegistration = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("إنشاء حساب جديد")
                                .font(.maJuTaBodyBold)
                            Text("Create Account")
                                .font(.system(size: 12))
                                .opacity(0.75)
                        }
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
                        HStack(spacing: MaJuTaSpacing.sm) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 16))
                            VStack(spacing: 2) {
                                Text("تصفح كضيف — بدون حساب")
                                    .font(.maJuTaBody)
                                Text("Browse as Guest — No account needed")
                                    .font(.system(size: 12))
                                    .opacity(0.75)
                            }
                        }
                        .foregroundColor(.maJuTaTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaJuTaSpacing.md)
                        .background(Color.maJuTaCard)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: MaJuTaRadius.button)
                                .stroke(Color.maJuTaGold.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Text("بياناتك في وضع الضيف تُحفظ على جهازك فقط\nGuest data is stored locally on your device only")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Spacer().frame(height: MaJuTaSpacing.xl)
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet().environmentObject(appState)
        }
    }
}

// MARK: - In-App Language Picker

struct LanguagePickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    private let languages: [(code: String, flag: String, name: String, subtitle: String)] = [
        ("ar", "🇸🇦", "العربية", "Arabic"),
        ("en", "🇬🇧", "English", "الإنجليزية"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(languages, id: \.code) { lang in
                    Button {
                        appState.appLanguage = lang.code
                        dismiss()
                    } label: {
                        HStack(spacing: MaJuTaSpacing.md) {
                            Text(lang.flag).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(lang.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if appState.appLanguage == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.maJuTaGold)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Language / اللغة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
