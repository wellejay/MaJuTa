import Foundation

struct InvestmentAsset: Identifiable, Codable {
    let id: UUID
    var symbol: String
    var name: String
    var market: InvestmentMarket
    var assetType: AssetType
    var units: Double
    var costBasis: Double
    var lastPrice: Double
    var lastPriceUpdated: Date
    var priceSource: String
    var ownerUserId: UUID
    var householdId: UUID
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        market: InvestmentMarket = .tadawul,
        assetType: AssetType = .stock,
        units: Double,
        costBasis: Double,
        lastPrice: Double,
        lastPriceUpdated: Date = Date(),
        priceSource: String = "manual",
        ownerUserId: UUID,
        householdId: UUID,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.market = market
        self.assetType = assetType
        self.units = units
        self.costBasis = costBasis
        self.lastPrice = lastPrice
        self.lastPriceUpdated = lastPriceUpdated
        self.priceSource = priceSource
        self.ownerUserId = ownerUserId
        self.householdId = householdId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties
    var currentMarketValue: Double { units * lastPrice }
    var totalCostBasis: Double { costBasis }
    var averagePrice: Double { units > 0 ? costBasis / units : 0 }
    var unrealizedProfitLoss: Double { currentMarketValue - costBasis }
    var returnPercentage: Double {
        guard costBasis > 0 else { return 0 }
        return (currentMarketValue - costBasis) / costBasis * 100
    }
    var isProfit: Bool { unrealizedProfitLoss >= 0 }
}

enum AssetType: String, Codable, CaseIterable {
    case stock         = "stock"
    case etf           = "etf"
    case reit          = "reit"
    case sukuk         = "sukuk"
    case international = "international"

    var displayName: String {
        switch self {
        case .stock:         return "أسهم"
        case .etf:           return "صناديق ETF"
        case .reit:          return "صناديق ريت"
        case .sukuk:         return "صكوك"
        case .international: return "أسهم دولية"
        }
    }

    var icon: String {
        switch self {
        case .stock:         return "chart.bar.fill"
        case .etf:           return "chart.pie.fill"
        case .reit:          return "building.2.fill"
        case .sukuk:         return "doc.text.fill"
        case .international: return "globe"
        }
    }
}

enum InvestmentMarket: String, Codable {
    case tadawul      = "TADAWUL"
    case international = "INTERNATIONAL"

    var displayName: String {
        switch self {
        case .tadawul:       return "تداول"
        case .international: return "دولي"
        }
    }
}
