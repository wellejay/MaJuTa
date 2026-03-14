import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod: AnalyticsPeriod = .month

    enum AnalyticsPeriod: String, CaseIterable {
        case week = "أسبوع"; case month = "شهر"; case year = "سنة"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    periodSelector
                    cashFlowChart
                    categoryBreakdown
                    monthlyTrend
                    keyRatios
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("التحليلات")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Button(period.rawValue) { withAnimation { selectedPeriod = period } }
                    .font(.maJuTaCaptionMedium)
                    .foregroundColor(selectedPeriod == period ? .maJuTaPrimary : .maJuTaTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MaJuTaSpacing.sm)
                    .background(selectedPeriod == period ? Color.maJuTaGold : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
            }
        }
        .padding(4)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
        .maJuTaCardShadow()
    }

    private var cashFlowChart: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("الدخل مقابل المصاريف")
                .font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)

            let income = dataStore.monthlyIncome()
            let expenses = dataStore.monthlyExpenses()
            let netFlow = max(income - expenses, 0)

            Chart {
                BarMark(x: .value("النوع", "الدخل"), y: .value("المبلغ", income))
                    .foregroundStyle(Color.maJuTaPositive).cornerRadius(8)
                BarMark(x: .value("النوع", "المصاريف"), y: .value("المبلغ", expenses))
                    .foregroundStyle(Color.maJuTaNegative).cornerRadius(8)
                BarMark(x: .value("النوع", "الصافي"), y: .value("المبلغ", netFlow))
                    .foregroundStyle(Color.maJuTaGold).cornerRadius(8)
            }
            .frame(height: 200)
            .chartYAxis { AxisMarks(position: .leading) }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("المصاريف حسب الفئة")
                .font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)

            let grouped = Dictionary(grouping: dataStore.transactions.filter { $0.amount < 0 }) { $0.categoryId }
            let totals = grouped.compactMap { (catId, txns) -> (TransactionCategory, Double)? in
                guard let cat = dataStore.category(for: catId) else { return nil }
                return (cat, txns.reduce(0) { $0 + abs($1.amount) })
            }.sorted { $0.1 > $1.1 }.prefix(6)

            let total = totals.reduce(0) { $0 + $1.1 }

            VStack(spacing: MaJuTaSpacing.sm) {
                ForEach(Array(totals), id: \.0.id) { cat, amount in
                    let pct = total > 0 ? amount / total : 0
                    HStack(spacing: MaJuTaSpacing.sm) {
                        SARText.compact(amount)
                            .frame(width: 64, alignment: .trailing)
                        GeometryReader { geo in
                            ZStack(alignment: .trailing) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.maJuTaBackground).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4).fill(Color(hex: cat.colorHex))
                                    .frame(width: geo.size.width * pct, height: 8)
                            }
                        }.frame(height: 8)
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon).font(.system(size: 12)).foregroundColor(Color(hex: cat.colorHex))
                            Text(cat.nameArabic).font(.maJuTaCaption).foregroundColor(.maJuTaTextPrimary)
                        }.frame(width: 100, alignment: .trailing)
                    }
                }
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var trendMonths: [(String, Double, Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "ar_SA")
        return (0..<6).compactMap { offset -> (String, Double, Double)? in
            guard let date = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            return (formatter.string(from: date), dataStore.monthlyIncome(for: date), dataStore.monthlyExpenses(for: date))
        }.reversed()
    }

    private var monthlyTrend: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("الاتجاه الشهري").font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)

            let months = trendMonths

            Chart {
                ForEach(months, id: \.0) { month, income, expenses in
                    LineMark(x: .value("الشهر", month), y: .value("المبلغ", income))
                        .foregroundStyle(Color.maJuTaPositive).symbol(Circle().strokeBorder(lineWidth: 2))
                    LineMark(x: .value("الشهر", month), y: .value("المبلغ", expenses))
                        .foregroundStyle(Color.maJuTaNegative).symbol(Circle().strokeBorder(lineWidth: 2))
                }
            }
            .frame(height: 180)

            HStack(spacing: MaJuTaSpacing.md) {
                Spacer()
                Label("المصاريف", systemImage: "circle.fill").foregroundColor(.maJuTaNegative)
                Label("الدخل", systemImage: "circle.fill").foregroundColor(.maJuTaPositive)
            }.font(.maJuTaCaption)
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var keyRatios: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("النسب المالية الرئيسية").font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)

            let income = dataStore.monthlyIncome()
            let obligationRatio = CashFlowEngine.fixedObligationRatio(
                fixedExpenses: dataStore.upcomingBillsTotal, monthlyIncome: income
            )
            let risk = CashFlowEngine.obligationRiskLevel(ratio: obligationRatio)

            VStack(spacing: 1) {
                ratioRow(label: "نسبة الالتزامات", value: obligationRatio.percentageFormatted,
                         status: risk.label, color: Color(hex: risk.colorHex))
                Divider()
                ratioRow(label: "معدل الادخار",
                         value: CashFlowEngine.savingsRate(savingsContributions: dataStore.plannedSavingsThisMonth, disposableIncome: income).percentageFormatted,
                         status: "جيد", color: .maJuTaPositive)
                Divider()
                ratioRow(label: "تغطية الطوارئ",
                         value: "\(String(format: "%.1f", dataStore.emergencyMonths)) أشهر",
                         status: dataStore.emergencyMonths >= 3 ? "جيد" : "يحتاج تحسين",
                         color: dataStore.emergencyMonths >= 3 ? .maJuTaPositive : .maJuTaWarning)
            }
            .background(Color.maJuTaBackground)
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func ratioRow(label: String, value: String, status: String, color: Color) -> some View {
        HStack {
            Text(status).font(.maJuTaCaptionMedium).foregroundColor(color)
                .padding(.horizontal, MaJuTaSpacing.sm).padding(.vertical, 4)
                .background(color.opacity(0.1)).clipShape(Capsule())
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value).font(.maJuTaBodyBold).foregroundColor(.maJuTaTextPrimary)
                Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            }
        }
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
    }
}
