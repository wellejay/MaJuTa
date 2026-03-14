import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()

            VStack(spacing: MaJuTaSpacing.xl) {
                Spacer()

                Image("MaJuTaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Text("مركز التحكم المالي")
                    .font(.maJuTaBody)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                VStack(spacing: MaJuTaSpacing.md) {
                    Button {
                        Task { await authService.authenticate() }
                    } label: {
                        HStack(spacing: MaJuTaSpacing.sm) {
                            Image(systemName: authService.biometricType == .faceID ? "faceid" : "touchid")
                                .font(.system(size: 20))
                            Text(authService.biometricType == .faceID ? "الدخول بـ Face ID" : "الدخول بـ Touch ID")
                                .font(.maJuTaBodyBold)
                        }
                        .foregroundColor(.maJuTaPrimary)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.maJuTaGold)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }

                    if let error = authService.authError {
                        Text(error).font(.maJuTaCaption).foregroundColor(.maJuTaNegative).multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, 48)
            }
        }
        .task { await authService.authenticate() }
    }
}
