import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject private var userService = UserService.shared
    @State private var selectedScheme: String = "system"
    @State private var notificationsEnabled = true
    @State private var biometricEnabled = true
    @State private var showResetAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showIncomeEdit = false
    @State private var incomeText: String = ""
    // Phone editing
    @State private var showPhoneEdit = false
    @State private var showCountryPicker = false
    @State private var selectedCountry = CountryPhoneCode.defaultCountry
    @State private var phoneInput = ""
    @State private var countrySearch = ""

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.md) {
                settingsSection(title: L("الدخل الشهري")) {
                    settingsRow(label: L("الراتب الشهري"), icon: "banknote.fill", color: "#22C55E") {
                        Button {
                            incomeText = String(Int(appState.monthlyIncome))
                            showIncomeEdit = true
                        } label: {
                            Text("\(Int(appState.monthlyIncome)) ﷼")
                                .font(.maJuTaBody)
                                .foregroundColor(.maJuTaGold)
                        }
                    }
                }
                .sheet(isPresented: $showIncomeEdit) {
                    NavigationStack {
                        VStack(spacing: MaJuTaSpacing.lg) {
                            HStack {
                                TextField("0", text: $incomeText)
                                    .keyboardType(.numberPad)
                                    .font(.maJuTaLargeNumber)
                                    .multilineTextAlignment(.trailing)
                                Text("﷼")
                                    .font(.maJuTaTitle1)
                                    .foregroundColor(.maJuTaGold)
                            }
                            .padding(MaJuTaSpacing.md)
                            .background(Color.maJuTaCard)
                            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
                            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                            .padding(.top, MaJuTaSpacing.xl)
                            Spacer()
                        }
                        .background(Color.maJuTaBackground)
                        .navigationTitle(L("تعديل الراتب"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(L("إلغاء")) { showIncomeEdit = false }
                                    .foregroundColor(.maJuTaTextSecondary)
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(L("حفظ")) {
                                    let newIncome = Double(incomeText) ?? appState.monthlyIncome
                                    appState.monthlyIncome = newIncome
                                    showIncomeEdit = false
                                }
                                .foregroundColor(.maJuTaGold)
                                .font(.maJuTaBodyBold)
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }

                settingsSection(title: L("معلومات الاتصال")) {
                    settingsRow(label: L("رقم الهاتف"), icon: "phone.fill", color: "#22C55E") {
                        Button {
                            initPhoneEdit()
                            showPhoneEdit = true
                        } label: {
                            let phone = userService.currentUser?.phoneNumber ?? ""
                            Text(phone.isEmpty ? L("إضافة") : phone)
                                .font(.maJuTaCaption)
                                .foregroundColor(phone.isEmpty ? .maJuTaTextSecondary : .maJuTaGold)
                        }
                    }
                }
                .sheet(isPresented: $showPhoneEdit) { phoneEditSheet }

                settingsSection(title: L("المظهر")) {
                    settingsRow(label: L("وضع العرض"), icon: "moon.fill", color: "#0C2031") {
                        Picker("", selection: $selectedScheme) {
                            Text(L("تلقائي")).tag("system")
                            Text(L("فاتح")).tag("light")
                            Text(L("داكن")).tag("dark")
                        }
                        .pickerStyle(.segmented).frame(width: 160)
                    }
                    .onChange(of: selectedScheme) { _, val in
                        switch val {
                        case "light": appState.setColorScheme(.light)
                        case "dark": appState.setColorScheme(.dark)
                        default: appState.setColorScheme(nil)
                        }
                    }
                }

                settingsSection(title: L("الأمان")) {
                    settingsRow(label: "Face ID / Touch ID", icon: "faceid", color: "#22C55E") {
                        Toggle("", isOn: $biometricEnabled).tint(.maJuTaGold).labelsHidden()
                    }
                }

                settingsSection(title: L("الإشعارات")) {
                    settingsRow(label: L("تفعيل الإشعارات"), icon: "bell.fill", color: "#F2AE2E") {
                        Toggle("", isOn: $notificationsEnabled).tint(.maJuTaGold).labelsHidden()
                    }
                }

                settingsSection(title: L("البيانات")) {
                    settingsRow(label: L("تصدير CSV"), icon: "square.and.arrow.up", color: "#06B6D4") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                    Divider()
                    settingsRow(label: L("نسخ احتياطي iCloud"), icon: "icloud.fill", color: "#0C2031") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                }

                settingsSection(title: L("عن التطبيق")) {
                    settingsRow(label: L("MaJuTa — الإصدار 1.2.0"), icon: "info.circle.fill", color: "#6B7280") {
                        EmptyView()
                    }
                    Divider()
                    settingsRow(label: L("سياسة الخصوصية"), icon: "lock.shield.fill", color: "#0C2031") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                }

                Button(L("إعادة ضبط التطبيق")) {
                    showResetAlert = true
                }
                .font(.maJuTaCaption).foregroundColor(.maJuTaNegative.opacity(0.7))
                .padding(.top, MaJuTaSpacing.sm)
                .alert(L("إعادة ضبط التطبيق"), isPresented: $showResetAlert) {
                    Button(L("إلغاء"), role: .cancel) {}
                    Button(L("إعادة الضبط"), role: .destructive) {
                        DataStore.shared.reset()
                        appState.resetAll()
                    }
                } message: {
                    Text(L("سيتم حذف جميع بياناتك المحلية. هذا الإجراء لا يمكن التراجع عنه."))
                }

                Button(L("حذف الحساب نهائياً")) {
                    showDeleteAccountAlert = true
                }
                .font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
                .padding(.top, MaJuTaSpacing.xs)
                .alert(L("حذف الحساب"), isPresented: $showDeleteAccountAlert) {
                    Button(L("إلغاء"), role: .cancel) {}
                    Button(L("حذف نهائياً"), role: .destructive) {
                        Task {
                            await UserService.shared.deleteCurrentAccount()
                            await MainActor.run {
                                DataStore.shared.loans = []
                                appState.resetAll()
                            }
                        }
                    }
                } message: {
                    Text(L("سيتم حذف حسابك وجميع بياناتك بشكل دائم لا يمكن التراجع عنه. إذا كنت مالك الحساب، سيتم حذف بيانات العائلة بالكامل."))
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.md)
            .padding(.bottom, MaJuTaSpacing.xxxl)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle(L("الإعدادات"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Phone Edit Sheet

    private var phoneEditSheet: some View {
        NavigationStack {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Country picker button
                Button { showCountryPicker = true } label: {
                    HStack(spacing: MaJuTaSpacing.md) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                            .foregroundColor(.maJuTaTextSecondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(selectedCountry.flag + "  " + selectedCountry.name)
                                .font(.maJuTaBody)
                                .foregroundColor(.maJuTaTextPrimary)
                            Text(selectedCountry.dialCode)
                                .font(.maJuTaCaption)
                                .foregroundColor(.maJuTaGold)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                                .fill(Color.maJuTaGold.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "globe")
                                .font(.system(size: 16))
                                .foregroundColor(.maJuTaGold)
                        }
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()
                }
                .buttonStyle(.plain)

                // Phone number field
                HStack(spacing: MaJuTaSpacing.sm) {
                    TextField(selectedCountry.placeholder, text: $phoneInput)
                        .keyboardType(.phonePad)
                        .font(.maJuTaBody)
                        .foregroundColor(.maJuTaTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: phoneInput) { _, newValue in
                            let digits = newValue.filter { $0.isNumber }
                            let limited = String(digits.prefix(selectedCountry.digitCount))
                            let formatted = CountryPhoneCode.formatPhoneNumber(limited, pattern: selectedCountry.placeholder)
                            if formatted != newValue { phoneInput = formatted }
                        }
                    Text(selectedCountry.dialCode)
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.maJuTaGold)
                }
                .padding(MaJuTaSpacing.md)
                .background(Color.maJuTaCard)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .maJuTaCardShadow()

                Text(L("اختياري — رقم الهاتف ليس مطلوباً لاستخدام التطبيق"))
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .multilineTextAlignment(.center)

                if !(userService.currentUser?.phoneNumber ?? "").isEmpty {
                    Button {
                        if let user = userService.currentUser {
                            UserService.shared.updatePhoneNumber("", for: user.id)
                        }
                        showPhoneEdit = false
                    } label: {
                        Text(L("حذف رقم الهاتف"))
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaNegative)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.top, MaJuTaSpacing.md)
            .background(Color.maJuTaBackground)
            .navigationTitle(L("رقم الهاتف"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { showPhoneEdit = false }
                        .foregroundColor(.maJuTaTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("حفظ")) { savePhone() }
                        .foregroundColor(.maJuTaGold)
                        .font(.maJuTaBodyBold)
                }
            }
            .sheet(isPresented: $showCountryPicker) { countryPickerSheet }
        }
        .presentationDetents([.medium, .large])
    }

    private var countryPickerSheet: some View {
        NavigationStack {
            List(CountryPhoneCode.search(countrySearch)) { country in
                Button {
                    selectedCountry = country
                    phoneInput = ""
                    showCountryPicker = false
                } label: {
                    HStack {
                        Text(country.flag + "  " + country.name)
                            .font(.maJuTaBody)
                            .foregroundColor(.maJuTaTextPrimary)
                        Spacer()
                        Text(country.dialCode)
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaGold)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $countrySearch, prompt: L("ابحث عن دولة..."))
            .navigationTitle(L("اختر الدولة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("إغلاق")) { showCountryPicker = false }
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private func initPhoneEdit() {
        countrySearch = ""
        let existing = userService.currentUser?.phoneNumber ?? ""
        // Match longest dial code first to avoid e.g. "+1" matching before "+1868"
        let match = CountryPhoneCode.all
            .sorted { $0.dialCode.count > $1.dialCode.count }
            .first { existing.hasPrefix($0.dialCode) }
        if let country = match {
            selectedCountry = country
            let localDigits = String(existing.dropFirst(country.dialCode.count).filter { $0.isNumber })
            phoneInput = CountryPhoneCode.formatPhoneNumber(localDigits, pattern: country.placeholder)
        } else {
            selectedCountry = CountryPhoneCode.defaultCountry
            phoneInput = ""
        }
    }

    private func savePhone() {
        let digits = phoneInput.filter { $0.isNumber }
        let fullPhone = digits.isEmpty ? "" : selectedCountry.dialCode + digits
        if let user = userService.currentUser {
            UserService.shared.updatePhoneNumber(fullPhone, for: user.id)
        }
        showPhoneEdit = false
    }

    // MARK: - Section / Row builders

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(title).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            VStack(spacing: 1) { content() }
                .background(Color.maJuTaCard)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .maJuTaCardShadow()
        }
    }

    private func settingsRow<Content: View>(label: String, icon: String, color: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(spacing: MaJuTaSpacing.md) {
            trailing()
            Spacer()
            Text(label).font(.maJuTaBody).foregroundColor(.maJuTaTextPrimary)
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                    .fill(Color(hex: color).opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(Color(hex: color))
            }
        }.padding(MaJuTaSpacing.md)
    }
}
