import SwiftUI

struct EmergencyFundView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddFunds = false
    @State private var showWithdraw = false

    var months: Double { dataStore.emergencyMonths }
    var balance: Double { dataStore.emergencyFundBalance }
    var monthlyEssentials: Double { dataStore.monthlyEssentialExpenses > 0 ? dataStore.monthlyEssentialExpenses : 5000 }
    var targetBalance: Double { monthlyEssentials * 6 }
    var progress: Double { min(balance / targetBalance, 1.0) }
    var recommended: Double { max(targetBalance - balance, 0) / 6 }

    var coverageColor: Color {
        if months >= 6 { return .maJuTaPositive }
        if months >= 3 { return .maJuTaWarning }
        return .maJuTaNegative
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Hero
                heroSection

                // Monthly contribution status
                monthlyStatusCard

                // Coverage Detail
                coverageDetail

                // Recommendation
                recommendationCard

                // Essential Expenses Breakdown
                essentialBreakdown
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.lg)
            .padding(.bottom, MaJuTaSpacing.xxxl)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle("صندوق الطوارئ")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: MaJuTaSpacing.sm) {
                    Button {
                        showWithdraw = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.maJuTaNegative)
                    }
                    .disabled(dataStore.emergencyFundBalance <= 0)

                    Button {
                        showAddFunds = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.maJuTaGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFunds) {
            EmergencyFundTransactionSheet(mode: .deposit)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showWithdraw) {
            EmergencyFundTransactionSheet(mode: .withdrawal)
                .environmentObject(dataStore)
        }
    }

    private var heroSection: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            // Gauge
            ZStack {
                Circle()
                    .stroke(Color.maJuTaBackground, lineWidth: 16)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(coverageColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", months))
                        .font(.maJuTaHero)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("أشهر")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }

            SARText.largeNumber(balance)

            Text("الرصيد الحالي")
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.xl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    // MARK: - Monthly Status
    private var monthlyStatusCard: some View {
        let deposited = dataStore.emergencyDepositsThisMonth
        let target = dataStore.emergencyMonthlyContribution
        let isCompleted = deposited >= target && target > 0
        let isNotStarted = deposited == 0
        let bgColor: Color = isCompleted ? .maJuTaPositive : isNotStarted ? .maJuTaNegative : .maJuTaWarning

        return HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                Text(isCompleted ? "اكتملت مساهمة الشهر ✓" :
                     isNotStarted ? "لم تُموَّل هذا الشهر بعد" :
                     "مساهمة جزئية هذا الشهر")
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    if deposited > 0 {
                        SARText.compact(deposited, color: .white)
                        Text("من").font(.maJuTaCaption).foregroundColor(.white.opacity(0.8))
                    }
                    SARText.compact(target, color: .white.opacity(0.85))
                    Text("المستهدف الشهري").font(.maJuTaCaption).foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
            Image(systemName: isCompleted ? "checkmark.seal.fill" : isNotStarted ? "exclamationmark.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(MaJuTaSpacing.lg)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var coverageDetail: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            coverageStat(
                value: String(format: "%.1f", months),
                label: "أشهر حالياً",
                color: coverageColor
            )
            coverageStat(
                value: "6",
                label: "الهدف الموصى به",
                color: .maJuTaGold
            )
            VStack(spacing: 4) {
                SARText.compact(targetBalance)
                Text("المبلغ المستهدف")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(MaJuTaSpacing.md)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    private func coverageStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.maJuTaMediumNumber)
                .foregroundColor(color)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var recommendationCard: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                Text("المساهمة الشهرية الموصى بها")
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.white)
                SARText.mediumNumber(recommended, color: .white)
                Text("لتصل إلى 6 أشهر في 6 أشهر")
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(MaJuTaSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color(hex: "#EF4444"), Color(hex: "#B91C1C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var essentialBreakdown: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("المصاريف الأساسية الشهرية")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            SARText.mediumNumber(monthlyEssentials)

            Text("تشمل: الإيجار، البقالة، المرافق، الاتصالات، الوقود")
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }
}

// MARK: - Unified Deposit / Withdrawal Sheet
private struct EmergencyFundTransactionSheet: View {
    enum Mode { case deposit, withdrawal }

    let mode: Mode
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @FocusState private var focused: Bool

    var amount: Double { Double(amountText) ?? 0 }
    var balance: Double { dataStore.emergencyFundBalance }

    var isDeposit: Bool { mode == .deposit }
    var isValid: Bool {
        amount > 0 && (isDeposit || amount <= balance)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: MaJuTaSpacing.xl) {

                VStack(spacing: MaJuTaSpacing.sm) {
                    Image(systemName: isDeposit ? "plus.circle.fill" : "minus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isDeposit ? .maJuTaGold : .maJuTaNegative)
                    Text(isDeposit ? "إضافة مبلغ لصندوق الطوارئ" : "سحب من صندوق الطوارئ")
                        .font(.maJuTaTitle2)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("الرصيد الحالي: \(String(format: "%.0f", balance)) ﷼")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
                .padding(.top, MaJuTaSpacing.xl)

                VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                    Text("المبلغ (﷼)")
                        .font(.maJuTaBodyMedium)
                        .foregroundColor(.maJuTaTextPrimary)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.maJuTaTextPrimary)
                        .padding(MaJuTaSpacing.md)
                        .background(Color.maJuTaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                        .focused($focused)

                    // Withdrawal warning if amount exceeds balance
                    if !isDeposit && amount > balance && amount > 0 {
                        Text("لا يمكن سحب أكثر من الرصيد المتاح")
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaNegative)
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Button {
                    guard isValid else { return }
                    if isDeposit {
                        dataStore.depositToEmergencyFund(amount: amount)
                    } else {
                        dataStore.withdrawFromEmergencyFund(amount: amount)
                    }
                    dismiss()
                } label: {
                    let label = isDeposit
                        ? "إضافة \(amount > 0 ? String(format: "%.0f ﷼", amount) : "")"
                        : "سحب \(amount > 0 ? String(format: "%.0f ﷼", amount) : "")"
                    Text(label)
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(MaJuTaSpacing.md)
                        .background(isValid
                            ? (isDeposit ? Color.maJuTaGold : Color.maJuTaNegative)
                            : Color.maJuTaTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .disabled(!isValid)

                Spacer()
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(isDeposit ? "إضافة مبلغ" : "سحب مبلغ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("إلغاء") { dismiss() }
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }
            .onAppear { focused = true }
        }
    }
}
