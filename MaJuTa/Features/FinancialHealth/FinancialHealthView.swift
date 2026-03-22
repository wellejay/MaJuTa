import SwiftUI

struct FinancialHealthView: View {
    @EnvironmentObject var dataStore: DataStore

    var score: FinancialHealthScore {
        FinancialHealthEngine.calculateScore(
            savingsRate: dataStore.actualSavingsRate,
            emergencyMonths: dataStore.emergencyMonths,
            debtRatio: dataStore.fixedObligationRatio,
            spendingStability: dataStore.spendingStability,
            hasData: !dataStore.transactions.isEmpty
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                mainScoreCard
                componentScores
                insightsSection
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.lg)
            .padding(.bottom, MaJuTaSpacing.xxxl)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle(L("الصحة المالية"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var mainScoreCard: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            ZStack {
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(Color.maJuTaBackground, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(90))

                Circle()
                    .trim(from: 0.25, to: 0.25 + CGFloat(score.total / 100) * 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#EF4444"), Color(hex: "#F59E0B"), Color(hex: "#22C55E")],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(90))
                    .animation(.spring(duration: 1.5), value: score.total)

                VStack(spacing: 4) {
                    Text("\(Int(score.total))").font(.maJuTaHero).foregroundColor(.maJuTaTextPrimary)
                    Text(score.grade.label).font(.maJuTaBodyBold).foregroundColor(Color(hex: score.grade.colorHex))
                    Text(L("من 100")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                }
            }
            .accessibilityLabel(L("نقاط الصحة المالية: \(Int(score.total)) من 100 — \(score.grade.label)"))

            Text(score.grade.description)
                .font(.maJuTaBody).foregroundColor(.maJuTaTextSecondary)
                .multilineTextAlignment(.center).padding(.horizontal)
        }
        .frame(maxWidth: .infinity).padding(MaJuTaSpacing.xl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var componentScores: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text(L("تفاصيل النتيجة")).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)
            VStack(spacing: MaJuTaSpacing.sm) {
                scoreComponent(label: L("معدل الادخار"), score: score.savingsRateScore, weight: 30, icon: "banknote.fill", color: .maJuTaPositive)
                scoreComponent(label: L("تغطية الطوارئ"), score: score.emergencyCoverageScore, weight: 25, icon: "exclamationmark.shield.fill", color: .maJuTaNegative)
                scoreComponent(label: L("نسبة الديون"), score: score.debtRatioScore, weight: 25, icon: "creditcard.fill", color: .maJuTaOrange)
                scoreComponent(label: L("ثبات الإنفاق"), score: score.spendingStabilityScore, weight: 20, icon: "chart.bar.fill", color: .maJuTaGold)
            }
        }
    }

    private func scoreComponent(label: String, score: Double, weight: Int, icon: String, color: Color) -> some View {
        HStack(spacing: MaJuTaSpacing.md) {
            Text("\(Int(score))").font(.maJuTaBodyBold).foregroundColor(color).frame(width: 40, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text(L("وزن") + " \(weight)%").font(.maJuTaLabel).foregroundColor(.maJuTaTextSecondary)
                    Spacer()
                    Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.maJuTaBackground).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geo.size.width * score / 100, height: 6)
                    }
                }.frame(height: 6)
            }

            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color).frame(width: 24)
        }
        .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
        .accessibilityLabel(L("\(label): \(Int(score)) نقطة من 100 — الوزن \(weight)%"))
    }

    private var insightsSection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text(L("توصيات")).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)
            VStack(spacing: MaJuTaSpacing.sm) {
                insightCard(
                    icon: "exclamationmark.shield.fill",
                    color: dataStore.emergencyMonths >= 3 ? .maJuTaPositive : .maJuTaNegative,
                    title: dataStore.emergencyMonths >= 3 ? L("صندوق الطوارئ جيد") : L("صندوق الطوارئ يحتاج تعزيز"),
                    description: dataStore.emergencyMonths >= 3
                        ? "\(String(format: "%.1f", dataStore.emergencyMonths)) \(L("أشهر من التغطية"))"
                        : L("يُنصح بتوفير") + " \(String(format: "%.1f", max(3 - dataStore.emergencyMonths, 0))) " + L("أشهر إضافية")
                )
                let actualRate = dataStore.actualSavingsRate
                let rateColor: Color = actualRate >= 20 ? .maJuTaPositive : .maJuTaGold
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    color: rateColor,
                    title: actualRate >= 20 ? L("معدل الادخار ممتاز") : L("زيادة معدل الادخار"),
                    description: actualRate >= 20
                        ? L("معدل ادخارك الحالي") + " \(Int(actualRate))% — " + L("أعلى من الهدف المثالي 20%")
                        : L("معدل ادخارك الحالي") + " \(Int(actualRate))%، " + L("حاول رفعه إلى 20% من الدخل الشهري")
                )
            }
        }
    }

    private func insightCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                Text(title).font(.maJuTaBodyMedium).foregroundColor(.maJuTaTextPrimary)
                Text(description).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary).multilineTextAlignment(.trailing)
            }
            Spacer()
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            }
        }
        .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
        .accessibilityLabel(L("\(title): \(description)"))
    }
}
