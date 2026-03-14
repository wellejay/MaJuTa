import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firebaseAuth = FirebaseAuthService.shared
    @ObservedObject private var userService  = UserService.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var isChecking    = false
    @State private var isResending   = false
    @State private var statusMessage = ""
    @State private var statusIsError = false
    @State private var pulseScale: CGFloat = 1.0

    private var email: String {
        userService.currentUser?.email ?? ""
    }

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                Image("MaJuTaLogo")
                    .resizable().scaledToFit().frame(width: 140)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 60)

                Spacer()

                // Mail icon with pulse
                ZStack {
                    Circle()
                        .fill(Color.maJuTaGold.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                    Circle()
                        .fill(Color.maJuTaGold.opacity(0.08))
                        .frame(width: 110, height: 110)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.maJuTaGold, Color.white.opacity(0.9))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        pulseScale = 1.12
                    }
                }

                VStack(spacing: MaJuTaSpacing.sm) {
                    Text("تحقق من بريدك الإلكتروني")
                        .font(.maJuTaTitle2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("أرسلنا رابط التحقق إلى")
                        .font(.maJuTaCaption)
                        .foregroundColor(.white.opacity(0.65))

                    Text(email)
                        .font(.maJuTaBodyMedium)
                        .foregroundColor(.maJuTaGold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MaJuTaSpacing.xl)
                }
                .padding(.top, MaJuTaSpacing.xl)

                // Status message
                if !statusMessage.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: statusIsError ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text(statusMessage)
                            .font(.maJuTaCaption)
                    }
                    .foregroundColor(statusIsError ? .maJuTaNegative : .maJuTaPositive)
                    .padding(.top, MaJuTaSpacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer()

                // Action buttons
                VStack(spacing: MaJuTaSpacing.sm) {
                    // Primary: I've verified
                    Button {
                        Task { await checkVerification() }
                    } label: {
                        HStack(spacing: 8) {
                            if isChecking {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.maJuTaPrimary)
                                    .scaleEffect(0.85)
                            }
                            Text(isChecking ? "جارٍ التحقق..." : "لقد قمت بالتحقق ✓")
                                .font(.maJuTaBodyBold)
                                .foregroundColor(.maJuTaPrimary)
                        }
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.maJuTaGold)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }
                    .disabled(isChecking)

                    // Resend
                    Button {
                        Task { await resendEmail() }
                    } label: {
                        HStack(spacing: 6) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.7)
                            }
                            Text(isResending ? "جارٍ الإرسال..." : "إعادة إرسال البريد")
                                .font(.maJuTaCaptionMedium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }
                    .disabled(isResending)

                    // Skip
                    Button("تخطى للآن") {
                        finishAndProceed()
                    }
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, 4)
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, 48)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: statusMessage)
        // Auto-check when app returns to foreground (user clicked link in mail app → switched back)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !isChecking {
                Task { await checkVerification() }
            }
        }
    }

    // MARK: - Actions

    private func checkVerification() async {
        isChecking = true
        statusMessage = ""
        await FirebaseAuthService.shared.reloadVerificationStatus()
        isChecking = false
        if FirebaseAuthService.shared.isEmailVerified {
            finishAndProceed()
        } else {
            statusIsError = true
            statusMessage = "لم يتم التحقق بعد، تحقق من بريدك وأعد المحاولة"
        }
    }

    private func resendEmail() async {
        isResending = true
        statusMessage = ""
        do {
            try await FirebaseAuthService.shared.resendVerificationEmail()
            statusIsError = false
            statusMessage = "تم إعادة إرسال البريد بنجاح"
        } catch {
            statusIsError = true
            statusMessage = "تعذّر الإرسال، حاول مرة أخرى"
        }
        isResending = false
    }

    private func finishAndProceed() {
        authService.showEmailVerification = false
        authService.isAuthenticated = true
    }
}
