import Foundation

final class InvestmentEngine {

    // MARK: - Portfolio Value
    static func portfolioValue(assets: [InvestmentAsset]) -> Double {
        assets.reduce(0) { $0 + $1.currentMarketValue }
    }

    // MARK: - Total Cost Basis
    static func totalCostBasis(assets: [InvestmentAsset]) -> Double {
        assets.reduce(0) { $0 + $1.costBasis }
    }

    // MARK: - Total Profit/Loss
    static func totalProfitLoss(assets: [InvestmentAsset]) -> Double {
        portfolioValue(assets: assets) - totalCostBasis(assets: assets)
    }

    // MARK: - Overall Return %
    static func overallReturn(assets: [InvestmentAsset]) -> Double {
        let cost = totalCostBasis(assets: assets)
        guard cost > 0 else { return 0 }
        return totalProfitLoss(assets: assets) / cost * 100
    }

    // MARK: - Portfolio by Asset Type
    static func allocation(assets: [InvestmentAsset]) -> [AssetType: Double] {
        let total = portfolioValue(assets: assets)
        guard total > 0 else { return [:] }

        var result: [AssetType: Double] = [:]
        for type in AssetType.allCases {
            let typeValue = assets.filter { $0.assetType == type }
                                  .reduce(0) { $0 + $1.currentMarketValue }
            if typeValue > 0 {
                result[type] = typeValue / total * 100
            }
        }
        return result
    }

    // MARK: - Price Staleness Check
    static func isPriceStale(asset: InvestmentAsset) -> Bool {
        let hoursSinceUpdate = Date().timeIntervalSince(asset.lastPriceUpdated) / 3600
        switch asset.market {
        case .tadawul:       return hoursSinceUpdate > 24
        case .international: return hoursSinceUpdate > 24
        }
    }

    // MARK: - Update Price (Manual MVP)
    static func updatedAsset(_ asset: InvestmentAsset, newPrice: Double) -> InvestmentAsset {
        var updated = asset
        updated.lastPrice = newPrice
        updated.lastPriceUpdated = Date()
        updated.updatedAt = Date()
        return updated
    }
}
