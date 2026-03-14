import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedScheme: String = "system"
    @State private var notificationsEnabled = true
    @State private var biometricEnabled = true
    @State private var showResetAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showIncomeEdit = false
    @State private var incomeText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.md) {
                settingsSection(title: "الدخل الشهري") {
                    settingsRow(label: "الراتب الشهري", icon: "banknote.fill", color: "#22C55E") {
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
                        .navigationTitle("تعديل الراتب")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("إلغاء") { showIncomeEdit = false }
                                    .foregroundColor(.maJuTaTextSecondary)
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("حفظ") {
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

                settingsSection(title: "المظهر") {
                    settingsRow(label: "وضع العرض", icon: "moon.fill", color: "#0C2031") {
                        Picker("", selection: $selectedScheme) {
                            Text("تلقائي").tag("system")
                            Text("فاتح").tag("light")
                            Text("داكن").tag("dark")
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

                settingsSection(title: "الأمان") {
                    settingsRow(label: "Face ID / Touch ID", icon: "faceid", color: "#22C55E") {
                        Toggle("", isOn: $biometricEnabled).tint(.maJuTaGold).labelsHidden()
                    }
                }

                settingsSection(title: "الإشعارات") {
                    settingsRow(label: "تفعيل الإشعارات", icon: "bell.fill", color: "#F2AE2E") {
                        Toggle("", isOn: $notificationsEnabled).tint(.maJuTaGold).labelsHidden()
                    }
                }

                settingsSection(title: "البيانات") {
                    settingsRow(label: "تصدير CSV", icon: "square.and.arrow.up", color: "#06B6D4") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                    Divider()
                    settingsRow(label: "نسخ احتياطي iCloud", icon: "icloud.fill", color: "#0C2031") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                }

                settingsSection(title: "عن التطبيق") {
                    settingsRow(label: "MaJuTa — الإصدار 1.0.0", icon: "info.circle.fill", color: "#6B7280") {
                        EmptyView()
                    }
                    Divider()
                    settingsRow(label: "سياسة الخصوصية", icon: "lock.shield.fill", color: "#0C2031") {
                        Image(systemName: "chevron.left").font(.system(size: 12)).foregroundColor(.maJuTaTextSecondary)
                    }
                }

                Button("إعادة ضبط التطبيق") {
                    showResetAlert = true
                }
                .font(.maJuTaCaption).foregroundColor(.maJuTaNegative.opacity(0.7))
                .padding(.top, MaJuTaSpacing.sm)
                .alert("إعادة ضبط التطبيق", isPresented: $showResetAlert) {
                    Button("إلغاء", role: .cancel) {}
                    Button("إعادة الضبط", role: .destructive) {
                        DataStore.shared.reset()
                        appState.resetAll()
                    }
                } message: {
                    Text("سيتم حذف جميع بياناتك المحلية. هذا الإجراء لا يمكن التراجع عنه.")
                }

                Button("حذف الحساب نهائياً") {
                    showDeleteAccountAlert = true
                }
                .font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
                .padding(.top, MaJuTaSpacing.xs)
                .alert("حذف الحساب", isPresented: $showDeleteAccountAlert) {
                    Button("إلغاء", role: .cancel) {}
                    Button("حذف نهائياً", role: .destructive) {
                        Task {
                            await UserService.shared.deleteCurrentAccount()
                            await MainActor.run {
                                DataStore.shared.loans = []
                                appState.resetAll()
                            }
                        }
                    }
                } message: {
                    Text("سيتم حذف حسابك وجميع بياناتك بشكل دائم لا يمكن التراجع عنه. إذا كنت مالك الحساب، سيتم حذف بيانات العائلة بالكامل.")
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.md)
            .padding(.bottom, MaJuTaSpacing.xxxl)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle("الإعدادات")
        .navigationBarTitleDisplayMode(.large)
    }

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
