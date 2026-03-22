import SwiftUI

struct UserPickerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var userService = UserService.shared
    @State private var selectedUser: UserProfile? = nil
    @State private var pin = ""
    @State private var pinError = ""
    @State private var showPINEntry = false
    @State private var showLanguagePicker = false

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()
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
                            Text(L("Language / اللغة"))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.top, MaJuTaSpacing.sm)

                Image("MaJuTaLogo")
                    .resizable().scaledToFit().frame(width: 160)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(L("من يريد الدخول؟"))
                    .font(.maJuTaTitle2)
                    .foregroundColor(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MaJuTaSpacing.md) {
                        ForEach(userService.registeredUsers) { user in
                            Button { selectUser(user) } label: { userCard(user) }
                        }
                        // Add new user button
                        Button {
                            authService.showRegistration = true
                        } label: {
                            VStack(spacing: MaJuTaSpacing.sm) {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                    )
                                Text(L("حساب جديد"))
                                    .font(.maJuTaLabel)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(width: 88)
                        }
                    }
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                }

                if showPINEntry, let user = selectedUser {
                    pinEntryView(for: user)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Guest mode button — visible styled box
                Button {
                    UserService.shared.setupGuestUser()
                    DataStore.shared.loadGuestMode()
                    appState.isGuestMode = true
                } label: {
                    HStack(spacing: MaJuTaSpacing.sm) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 16))
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L("تصفح كضيف"))
                                .font(.maJuTaBodyBold)
                            Text(L("Browse as Guest"))
                                .font(.system(size: 12))
                                .opacity(0.75)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MaJuTaSpacing.md)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: MaJuTaRadius.button)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, MaJuTaSpacing.xl)
            }
            .padding(.top, MaJuTaSpacing.sm)
            .animation(.spring(), value: showPINEntry)
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet().environmentObject(appState)
        }
    }

    private func userCard(_ user: UserProfile) -> some View {
        VStack(spacing: MaJuTaSpacing.sm) {
            Circle()
                .fill(Color(hex: user.avatarColorHex).opacity(0.3))
                .frame(width: 72, height: 72)
                .overlay(
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.maJuTaTitle2)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(
                            selectedUser?.id == user.id ? Color.maJuTaGold : Color.clear,
                            lineWidth: 3
                        )
                )
            Text(user.name)
                .font(.maJuTaLabel)
                .foregroundColor(.white)
            Text(user.username.isEmpty ? user.role.displayName : "@\(user.username)")
                .font(.maJuTaLabel)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 88)
    }

    private func pinEntryView(for user: UserProfile) -> some View {
        VStack(spacing: MaJuTaSpacing.md) {
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? Color.maJuTaGold : Color.white.opacity(0.3))
                        .frame(width: 14, height: 14)
                }
            }
            if !pinError.isEmpty {
                Text(pinError)
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaNegative)
            }
            PINPadView(pin: $pin, maxDigits: 6) {
                verifyAndLogin(user: user, pin: pin)
            }
        }
    }

    private func selectUser(_ user: UserProfile) {
        selectedUser = user
        pin = ""
        pinError = isLockedOut(user)
            ? L("الحساب مقفل. حاول بعد \(lockoutRemaining(user) / 60 + 1) دقيقة")
            : ""
        withAnimation { showPINEntry = true }
        Task { await authService.authenticate(as: user) }
    }

    // MARK: - PIN Brute-Force Protection
    private static let maxAttempts = 5
    private static let lockoutSeconds: Double = 15 * 60 // 15 minutes

    private func lockoutKey(for user: UserProfile) -> String { "pin_lockout_until_\(user.id.uuidString)" }
    private func attemptsKey(for user: UserProfile) -> String { "pin_attempts_\(user.id.uuidString)" }

    private func isLockedOut(_ user: UserProfile) -> Bool {
        guard let str = KeychainService.getString(for: lockoutKey(for: user)),
              let until = Double(str) else { return false }
        return Date().timeIntervalSince1970 < until
    }

    private func lockoutRemaining(_ user: UserProfile) -> Int {
        guard let str = KeychainService.getString(for: lockoutKey(for: user)),
              let until = Double(str) else { return 0 }
        return max(0, Int(until - Date().timeIntervalSince1970))
    }

    private func recordFailedAttempt(for user: UserProfile) {
        let key = attemptsKey(for: user)
        let attempts = (Int(KeychainService.getString(for: key) ?? "0") ?? 0) + 1
        KeychainService.set(String(attempts), for: key)
        if attempts >= Self.maxAttempts {
            let until = Date().timeIntervalSince1970 + Self.lockoutSeconds
            KeychainService.set(String(until), for: lockoutKey(for: user))
            KeychainService.set("0", for: key)
        }
    }

    private func clearAttempts(for user: UserProfile) {
        KeychainService.set("0", for: attemptsKey(for: user))
        KeychainService.delete(for: lockoutKey(for: user))
    }

    private func verifyAndLogin(user: UserProfile, pin: String) {
        if isLockedOut(user) {
            let mins = lockoutRemaining(user) / 60 + 1
            pinError = L("الحساب مقفل. حاول بعد \(mins) دقيقة")
            self.pin = ""
            return
        }
        if UserService.shared.verifyPIN(pin, for: user) {
            clearAttempts(for: user)
            UserService.shared.setCurrentUser(user)
            UserService.shared.signInToFirebase(user: user, pin: pin)
            authService.isAuthenticated = true
        } else {
            recordFailedAttempt(for: user)
            if isLockedOut(user) {
                pinError = L("تم قفل الحساب 15 دقيقة بعد محاولات متعددة")
            } else {
                let attempts = Int(KeychainService.getString(for: attemptsKey(for: user)) ?? "0") ?? 0
                let remaining = Self.maxAttempts - attempts
                pinError = L("رمز PIN غير صحيح — \(remaining) محاولات متبقية")
            }
            self.pin = ""
        }
    }
}
