import SwiftUI

struct UserPickerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var userService = UserService.shared
    @State private var selectedUser: UserProfile? = nil
    @State private var pin = ""
    @State private var pinError = ""
    @State private var showPINEntry = false

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()
            VStack(spacing: MaJuTaSpacing.xl) {
                Image("MaJuTaLogo")
                    .resizable().scaledToFit().frame(width: 160)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("من يريد الدخول؟")
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
                                Text("حساب جديد")
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

                // Guest mode option
                Button {
                    UserService.shared.setupGuestUser()
                    DataStore.shared.loadGuestMode()
                    appState.isGuestMode = true
                } label: {
                    Text("تصفح كضيف — بدون حساب")
                        .font(.maJuTaCaption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, MaJuTaSpacing.sm)
                }
                .padding(.bottom, MaJuTaSpacing.xl)
            }
            .padding(.top, MaJuTaSpacing.xl)
            .animation(.spring(), value: showPINEntry)
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
        pinError = ""
        withAnimation { showPINEntry = true }
        // Try biometric first
        Task { await authService.authenticate(as: user) }
    }

    private func verifyAndLogin(user: UserProfile, pin: String) {
        if UserService.shared.verifyPIN(pin, for: user) {
            UserService.shared.setCurrentUser(user)
            // Sign in to Firebase Auth with the verified PIN
            UserService.shared.signInToFirebase(user: user, pin: pin)
            DataStore.shared.loadForCurrentUser()
            authService.isAuthenticated = true
        } else {
            pinError = "رمز PIN غير صحيح"
            self.pin = ""
        }
    }
}
