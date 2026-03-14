import SwiftUI
import Charts

struct InvestmentsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddAsset = false

    var totalValue: Double { InvestmentEngine.portfolioValue(assets: dataStore.investments) }
    var totalCost: Double { InvestmentEngine.totalCostBasis(assets: dataStore.investments) }
    var totalPL: Double { InvestmentEngine.totalProfitLoss(assets: dataStore.investments) }
    var totalReturn: Double { InvestmentEngine.overallReturn(assets: dataStore.investments) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    // Portfolio Summary
                    portfolioHeader

                    // Asset Type Breakdown
                    if !dataStore.investments.isEmpty {
                        allocationSection
                    }

                    // Asset List
                    assetList

                    // Empty State
                    if dataStore.investments.isEmpty {
                        emptyPortfolio
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("الاستثمارات")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddAsset = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.maJuTaGold)
                    }
                }
            }
            .sheet(isPresented: $showAddAsset) {
                AddInvestmentView()
                    .environmentObject(dataStore)
            }
        }
    }

    // MARK: - Portfolio Header
    private var portfolioHeader: some View {
        ZStack {
            LinearGradient.navyGradient
            VStack(spacing: MaJuTaSpacing.md) {
                Text("إجمالي المحفظة")
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.7))
                SARText.hero(totalValue, color: .white)

                HStack(spacing: MaJuTaSpacing.lg) {
                    plStatSAR(
                        label: "الربح / الخسارة",
                        amount: totalPL
                    )
                    Divider().frame(height: 30).background(Color.white.opacity(0.3))
                    plStat(
                        label: "نسبة العائد",
                        value: totalReturn.percentageFormatted,
                        positive: totalReturn >= 0
                    )
                }
            }
            .padding(MaJuTaSpacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func plStat(label: String, value: String, positive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.maJuTaBodyBold)
                .foregroundColor(positive ? .maJuTaPositive : .maJuTaNegative)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func plStatSAR(label: String, amount: Double) -> some View {
        VStack(spacing: 4) {
            SARText.signed(amount)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Allocation
    private var allocationSection: some View {
        let allocation = InvestmentEngine.allocation(assets: dataStore.investments)

        return VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text("توزيع المحفظة")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            VStack(spacing: MaJuTaSpacing.sm) {
                ForEach(allocation.sorted(by: { $0.value > $1.value }), id: \.key) { type, pct in
                    HStack {
                        Text(String(format: "%.1f%%", pct))
                            .font(.maJuTaCaptionMedium)
                            .foregroundColor(.maJuTaTextSecondary)
                            .frame(width: 48, alignment: .trailing)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(assetColor(type))
                                .frame(width: geo.size.width * pct / 100, height: 8)
                        }
                        .frame(height: 8)
                        Text(type.displayName)
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaTextPrimary)
                    }
                }
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    // MARK: - Asset List
    private var assetList: some View {
        VStack(spacing: 1) {
            ForEach(dataStore.investments) { asset in
                NavigationLink(destination: AssetDetailView(asset: asset)) {
                    AssetRowView(asset: asset)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var emptyPortfolio: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.maJuTaTextSecondary.opacity(0.4))
            Text("لا توجد استثمارات")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextSecondary)
            Text("أضف استثماراتك لتتبع أداء محفظتك")
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }

    private func assetColor(_ type: AssetType) -> Color {
        switch type {
        case .stock:         return Color(hex: "#F2AE2E")
        case .etf:           return Color(hex: "#22C55E")
        case .reit:          return Color(hex: "#06B6D4")
        case .sukuk:         return Color(hex: "#8B5CF6")
        case .international: return Color(hex: "#F27F1B")
        }
    }
}

// MARK: - Asset Row
struct AssetRowView: View {
    let asset: InvestmentAsset

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            // PL
            VStack(alignment: .trailing, spacing: 2) {
                SARText.bodyBold(asset.unrealizedProfitLoss,
                    color: asset.isProfit ? .maJuTaPositive : .maJuTaNegative)
                Text(asset.returnPercentage.percentageFormatted)
                    .font(.maJuTaCaption)
                    .foregroundColor(asset.isProfit ? .maJuTaPositive : .maJuTaNegative)
            }

            Spacer()

            // Info
            VStack(alignment: .trailing, spacing: 2) {
                Text(asset.name)
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.maJuTaTextPrimary)
                Text("\(asset.units, specifier: "%.0f") وحدة · \(asset.lastPrice.sarFormattedDecimal)")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }

            // Type Badge
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                    .fill(Color.maJuTaPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: asset.assetType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.maJuTaPrimary)
            }
        }
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
    }
}

// MARK: - Asset Detail
struct AssetDetailView: View {
    let asset: InvestmentAsset
    @State private var showUpdatePrice = false
    @State private var newPrice = ""

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Hero
                VStack(spacing: MaJuTaSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                            .fill(Color.maJuTaPrimary.opacity(0.1))
                            .frame(width: 72, height: 72)
                        Image(systemName: asset.assetType.icon)
                            .font(.system(size: 28))
                            .foregroundColor(.maJuTaPrimary)
                    }
                    Text(asset.name)
                        .font(.maJuTaTitle2)
                    Text(asset.symbol)
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                    SARText.hero(asset.currentMarketValue)
                }
                .frame(maxWidth: .infinity)
                .padding(MaJuTaSpacing.lg)
                .background(Color.maJuTaCard)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .maJuTaCardShadow()

                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MaJuTaSpacing.sm) {
                    investmentStat(label: "الوحدات", value: String(format: "%.0f", asset.units))
                    investmentStat(label: "متوسط السعر", value: asset.averagePrice.sarFormattedDecimal)
                    investmentStat(label: "السعر الحالي", value: asset.lastPrice.sarFormattedDecimal)
                    investmentStat(
                        label: "الربح / الخسارة",
                        amount: asset.unrealizedProfitLoss
                    )
                }

                // Update Price (Manual MVP)
                Button {
                    newPrice = String(format: "%.2f", asset.lastPrice)
                    showUpdatePrice = true
                } label: {
                    Label("تحديث السعر يدوياً", systemImage: "arrow.clockwise")
                        .font(.maJuTaBodyMedium)
                        .foregroundColor(.maJuTaGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.maJuTaGold.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.lg)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUpdatePrice) {
            NavigationStack {
                VStack(spacing: MaJuTaSpacing.lg) {
                    HStack {
                        TextField("0.00", text: $newPrice)
                            .keyboardType(.decimalPad)
                            .font(.maJuTaLargeNumber)
                            .multilineTextAlignment(.trailing)
                        Text("﷼")
                            .font(.maJuTaTitle1)
                            .foregroundColor(.maJuTaGold)
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                    .padding(.top, MaJuTaSpacing.xl)
                    Spacer()
                }
                .background(Color.maJuTaBackground)
                .navigationTitle("تحديث السعر")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("إلغاء") { showUpdatePrice = false }
                            .foregroundColor(.maJuTaTextSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("حفظ") {
                            if let price = Double(newPrice), price > 0 {
                                DataStore.shared.updateInvestmentPrice(assetId: asset.id, newPrice: price)
                            }
                            showUpdatePrice = false
                        }
                        .foregroundColor(.maJuTaGold)
                        .font(.maJuTaBodyBold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func investmentStat(label: String, value: String, color: Color = .maJuTaTextPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.maJuTaBodyBold)
                .foregroundColor(color)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func investmentStat(label: String, amount: Double) -> some View {
        VStack(spacing: 4) {
            SARText.signed(amount)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }
}

// MARK: - Add Investment
struct AddInvestmentView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var symbol = ""
    @State private var name = ""
    @State private var units = ""
    @State private var costBasis = ""
    @State private var lastPrice = ""
    @State private var selectedType: AssetType = .stock
    @State private var selectedMarket: InvestmentMarket = .tadawul

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    // Type Selector
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                        Text("نوع الأصل")
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MaJuTaSpacing.sm) {
                                ForEach(AssetType.allCases, id: \.self) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .font(.maJuTaCaptionMedium)
                                        .foregroundColor(selectedType == type ? .maJuTaPrimary : .maJuTaTextSecondary)
                                        .padding(.horizontal, MaJuTaSpacing.sm)
                                        .padding(.vertical, MaJuTaSpacing.xs)
                                        .background(selectedType == type ? Color.maJuTaGold : Color.maJuTaCard)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    // Fields
                    VStack(spacing: 1) {
                        addField(label: "الرمز (مثال: 2222)", text: $symbol)
                        Divider()
                        addField(label: "اسم الشركة", text: $name)
                        Divider()
                        addField(label: "عدد الوحدات", text: $units, keyboard: .decimalPad)
                        Divider()
                        addField(label: "تكلفة الشراء الإجمالية (﷼)", text: $costBasis, keyboard: .decimalPad)
                        Divider()
                        addField(label: "السعر الحالي (﷼)", text: $lastPrice, keyboard: .decimalPad)
                    }
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    Button("إضافة للمحفظة") {
                        saveAsset()
                    }
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.maJuTaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .padding(MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("أصل جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
    }

    private func addField(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            TextField(label, text: text)
                .keyboardType(keyboard)
                .font(.maJuTaBody)
                .multilineTextAlignment(.trailing)
            Spacer()
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(MaJuTaSpacing.md)
    }

    private func saveAsset() {
        let asset = InvestmentAsset(
            symbol: symbol,
            name: name,
            market: selectedMarket,
            assetType: selectedType,
            units: Double(units) ?? 0,
            costBasis: Double(costBasis) ?? 0,
            lastPrice: Double(lastPrice) ?? 0,
            ownerUserId: UserService.shared.currentUser?.id ?? UUID(),
            householdId: UserService.shared.currentUser?.householdId ?? UUID()
        )
        dataStore.addInvestment(asset)
        dismiss()
    }
}
