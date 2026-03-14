import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage: Int = 0
    @State private var userName: String = ""
    @State private var monthlyIncome: String = ""
    @State private var selectedLanguage: AppLanguage = .arabic
    @State private var bankName: String = ""
    @State private var ibanNumber: String = ""

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back + indicator
                HStack {
                    // Back button (hidden on page 0)
                    if currentPage > 0 {
                        Button {
                            withAnimation(.spring()) { currentPage -= 1 }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("رجوع")
                                    .font(.maJuTaCaptionMedium)
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Spacer().frame(width: 60)
                    }

                    Spacer()

                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<4) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.maJuTaGold : Color.white.opacity(0.3))
                                .frame(width: i == currentPage ? 24 : 8, height: 4)
                        }
                    }
                    .animation(.spring(), value: currentPage)

                    Spacer()
                    // Invisible spacer to balance back button
                    Spacer().frame(width: 60)
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.top, 60)

                Spacer()

                // Page Content
                switch currentPage {
                case 0: welcomePage
                case 1: languagePage
                case 2: incomePage
                case 3: accountPage
                default: welcomePage
                }

                Spacer()

                // Navigation Button
                Button(action: nextPage) {
                    HStack {
                        Text(currentPage == 3 ? "ابدأ الآن" : "التالي")
                            .font(.maJuTaBodyBold)
                        Image(systemName: "arrow.left")
                    }
                    .foregroundColor(.maJuTaPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.maJuTaGold)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            // Pre-fill name from registration if available
            if userName.isEmpty, let regName = UserService.shared.currentUser?.name {
                userName = regName
            }
        }
    }

    // MARK: - Pages
    private var welcomePage: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            Image("MaJuTaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 240)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: MaJuTaSpacing.sm) {
                Text("مركز التحكم المالي لعائلتك")
                    .font(.maJuTaBody)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                featureRow(icon: "checkmark.circle.fill", text: "تتبع الدخل والمصاريف")
                featureRow(icon: "checkmark.circle.fill", text: "إدارة الفواتير والالتزامات")
                featureRow(icon: "checkmark.circle.fill", text: "أهداف الادخار والاستثمار")
                featureRow(icon: "checkmark.circle.fill", text: "تحليل الصحة المالية")
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        }
    }

    private var languagePage: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            Text("اختر اللغة")
                .font(.maJuTaTitle1)
                .foregroundColor(.white)

            VStack(spacing: MaJuTaSpacing.md) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        selectedLanguage = lang
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .font(.maJuTaBodyBold)
                                .foregroundColor(selectedLanguage == lang ? .maJuTaPrimary : .white)
                            Spacer()
                            if selectedLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.maJuTaGold)
                            }
                        }
                        .padding(MaJuTaSpacing.md)
                        .background(
                            selectedLanguage == lang
                                ? Color.maJuTaGold
                                : Color.white.opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    }
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        }
    }

    private var incomePage: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            VStack(spacing: MaJuTaSpacing.sm) {
                Text("ما هو راتبك الشهري؟")
                    .font(.maJuTaTitle1)
                    .foregroundColor(.white)
                Text("نستخدمه لحساب ميزانيتك")
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(spacing: MaJuTaSpacing.md) {
                HStack {
                    TextField("0", text: $monthlyIncome)
                        .keyboardType(.numberPad)
                        .font(.maJuTaLargeNumber)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)

                    Text("﷼")
                        .font(.maJuTaTitle1)
                        .foregroundColor(.maJuTaGold)
                }
                .padding(MaJuTaSpacing.md)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))

                TextField("", text: $userName,
                    prompt: Text("مثال: محمد الأحمدي").foregroundColor(.white.opacity(0.5)))
                    .font(.maJuTaBody)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .padding(MaJuTaSpacing.md)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        }
    }

    private var accountPage: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            VStack(spacing: MaJuTaSpacing.sm) {
                Text("أضف حسابك البنكي")
                    .font(.maJuTaTitle1)
                    .foregroundColor(.white)
                Text("يمكنك إضافة المزيد لاحقاً")
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(spacing: MaJuTaSpacing.md) {
                onboardingField(placeholder: "اسم البنك (مثال: البنك الأهلي)", text: $bankName)
                onboardingField(placeholder: "رقم الآيبان (SA00 0000 0000 0000)", text: $ibanNumber, keyboardType: .asciiCapable)
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        }
    }

    // MARK: - Helpers
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            Text(text)
                .font(.maJuTaBody)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: icon)
                .foregroundColor(.maJuTaGold)
        }
    }

    private func onboardingField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        TextField("", text: text,
            prompt: Text(placeholder).foregroundColor(.white.opacity(0.5)))
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .font(.maJuTaBody)
            .foregroundColor(.white)
            .multilineTextAlignment(.trailing)
            .padding(MaJuTaSpacing.md)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
    }

    private func nextPage() {
        if currentPage < 3 {
            withAnimation(.spring()) { currentPage += 1 }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        appState.userName = userName
        let income = Double(monthlyIncome) ?? 0
        appState.monthlyIncome = income
        appState.hasCompletedOnboarding = true

        guard let user = UserService.shared.currentUser else { return }

        // Create bank account from onboarding data
        let accountName = bankName.isEmpty ? "الحساب الرئيسي" : bankName
        let account = Account(
            name: accountName,
            type: .bank,
            balance: income,  // seed with first salary
            institution: bankName,
            ownerUserId: user.id,
            householdId: user.householdId,
            isShared: false
        )
        DataStore.shared.addAccount(account)

        // Create initial salary transaction if income > 0
        if income > 0 {
            let salaryCategory = DataStore.shared.categories.first { $0.name == "Salary" }
            if let cat = salaryCategory {
                let salaryTx = Transaction(
                    amount: income,
                    categoryId: cat.id,
                    accountId: account.id,
                    merchant: "الراتب الشهري",
                    paymentMethod: .bankTransfer,
                    note: "راتب أول شهر",
                    isRecurring: true,
                    ownerUserId: user.id,
                    createdByUserId: user.id
                )
                DataStore.shared.addTransaction(salaryTx)
            }
        }
    }
}
