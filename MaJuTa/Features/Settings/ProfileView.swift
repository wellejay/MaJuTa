import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject private var firebaseAuth = FirebaseAuthService.shared

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showRemoveAlert = false
    @State private var resentEmailConfirm = false
    @State private var resendEmailError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    if !firebaseAuth.isEmailVerified && firebaseAuth.firebaseUID != nil {
                        emailVerificationBanner
                    }
                    profileHeader
                    quickStats
                    menuSection(title: L("الإدارة"), items: [
                        MenuItem(title: L("الحسابات"), icon: "creditcard.fill", color: "#0C2031",
                                 destination: AnyView(AccountsView().environmentObject(dataStore))),
                        MenuItem(title: L("العائلة والمشاركة"), icon: "person.2.fill", color: "#06B6D4",
                                 destination: AnyView(FamilyView().environmentObject(dataStore))),
                        MenuItem(title: L("الأقساط BNPL"), icon: "calendar.badge.plus", color: "#F27F1B",
                                 destination: AnyView(InstallmentsView().environmentObject(dataStore))),
                        MenuItem(title: L("التحليلات"), icon: "chart.bar.xaxis", color: "#22C55E",
                                 destination: AnyView(AnalyticsView().environmentObject(dataStore))),
                        MenuItem(title: L("الصحة المالية"), icon: "heart.text.square.fill", color: "#EF4444",
                                 destination: AnyView(FinancialHealthView().environmentObject(dataStore))),
                    ])
                    menuSection(title: L("الإعدادات"), items: [
                        MenuItem(title: L("الإعدادات العامة"), icon: "gearshape.fill", color: "#6B7280",
                                 destination: AnyView(SettingsView().environmentObject(appState).environmentObject(dataStore))),
                    ])
                    Button {
                        if appState.isGuestMode {
                            appState.resetAll()
                        } else {
                            authService.lock()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label(L("تسجيل الخروج"), systemImage: "lock.fill")
                                .font(.maJuTaBodyMedium).foregroundColor(.maJuTaNegative)
                                .accessibilityLabel(appState.isGuestMode ? L("الخروج من وضع الضيف") : L("تسجيل الخروج من الحساب"))
                            Spacer()
                        }
                        .padding(MaJuTaSpacing.md)
                        .background(Color.maJuTaNegativeBg)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("الحساب"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileHeader: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                Text(appState.userName.isEmpty ? L("المستخدم") : appState.userName)
                    .font(.maJuTaTitle2).foregroundColor(.maJuTaTextPrimary)
                let uname = UserService.shared.currentUser?.username ?? ""
                Text(uname.isEmpty ? L("عضو MaJuTa") : "@\(uname)")
                    .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            }
            Spacer()
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                avatarCircle(size: 72)
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.maJuTaGold)
                            .frame(width: 22, height: 22)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 10)).foregroundColor(.white))
                            .offset(x: 2, y: 2)
                    }
            }
            .accessibilityLabel(L("تغيير صورة الملف الشخصي"))
            .onChange(of: photosPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        appState.saveProfileImage(img)
                    }
                }
            }
            .contextMenu {
                if appState.profileImage != nil {
                    Button(role: .destructive) { showRemoveAlert = true } label: {
                        Label(L("حذف الصورة"), systemImage: "trash")
                    }
                }
            }
        }
        .padding(MaJuTaSpacing.lg).background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
        .alert(L("حذف صورة الملف الشخصي؟"), isPresented: $showRemoveAlert) {
            Button(L("حذف"), role: .destructive) { appState.deleteProfileImage() }
            Button(L("إلغاء"), role: .cancel) {}
        }
    }

    // MARK: - Email Verification Banner
    private var emailVerificationBanner: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(L("لم يتم التحقق من بريدك الإلكتروني"))
                    .font(.maJuTaBodyBold).foregroundColor(.white)
                Text(L("تحقق من صندوق الوارد وانقر على الرابط"))
                    .font(.maJuTaCaption).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            VStack(spacing: 6) {
                Button {
                    Task {
                        await firebaseAuth.reloadVerificationStatus()
                    }
                } label: {
                    Text(L("تحديث"))
                        .font(.maJuTaCaption).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                }
                .accessibilityLabel(L("تحديث حالة التحقق من البريد الإلكتروني"))
                Button {
                    Task {
                        do {
                            try await firebaseAuth.resendVerificationEmail()
                            resentEmailConfirm = true
                        } catch {
                            resendEmailError = error.localizedDescription
                        }
                    }
                } label: {
                    Text(L("إعادة الإرسال"))
                        .font(.maJuTaCaption).foregroundColor(.white.opacity(0.8))
                }
                .accessibilityLabel(L("إعادة إرسال رابط التحقق من البريد الإلكتروني"))
            }
        }
        .padding(MaJuTaSpacing.md)
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .alert(L("تم إرسال رابط التحقق"), isPresented: $resentEmailConfirm) {
            Button(L("حسناً"), role: .cancel) {}
        } message: {
            Text(L("تحقق من بريدك الإلكتروني وانقر على الرابط"))
        }
    }

    @ViewBuilder
    private func avatarCircle(size: CGFloat) -> some View {
        if let img = appState.profileImage {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient.navyGradient)
                .frame(width: size, height: size)
                .overlay(
                    Text(appState.userName.prefix(1).uppercased())
                        .font(size >= 60 ? .maJuTaTitle2 : .maJuTaBodyBold)
                        .foregroundColor(.white)
                )
        }
    }

    private var quickStats: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            VStack(spacing: 4) {
                SARText.compact(dataStore.netWorth)
                    .accessibilityLabel(L("صافي الثروة: \(String(format: "%.0f", dataStore.netWorth)) ريال سعودي"))
                Text(L("صافي الثروة")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            }
            .frame(maxWidth: .infinity).padding(MaJuTaSpacing.md)
            .background(Color.maJuTaCard).clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
            statCard(value: "\(dataStore.savingsGoals.count)", label: L("أهداف"))
            statCard(value: "\(dataStore.accounts.count)", label: L("حسابات"))
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.maJuTaBodyBold).foregroundColor(.maJuTaTextPrimary)
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity).padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard).clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
    }

    private func menuSection(title: String, items: [MenuItem]) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(title).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            VStack(spacing: 1) {
                ForEach(items) { item in
                    NavigationLink(destination: item.destination) {
                        HStack(spacing: MaJuTaSpacing.md) {
                            Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                            Spacer()
                            Text(item.title).font(.maJuTaBody).foregroundColor(.maJuTaTextPrimary)
                            ZStack {
                                RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                                    .fill(Color(hex: item.color).opacity(0.1)).frame(width: 36, height: 36)
                                Image(systemName: item.icon).font(.system(size: 16)).foregroundColor(Color(hex: item.color))
                            }
                        }
                        .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L("الانتقال إلى \(item.title)"))
                    if item.id != items.last?.id { Divider() }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: String
    let destination: AnyView
}
