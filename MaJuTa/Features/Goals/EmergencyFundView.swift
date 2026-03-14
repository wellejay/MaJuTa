import SwiftUI

struct EmergencyFundView: View {
    @EnvironmentObject var dataStore: DataStore

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
