import Foundation

public struct FoundationContext {
    public let compactSchema: String
    public let portfolioSummary: String
    public let lastUpdated: Date
}

public final class FoundationContextManager {
    public static let shared = FoundationContextManager()
    private var cached: FoundationContext?
    private let expirationInterval: TimeInterval = 3600

    private init() {}

    internal func getOptimizedContext(container: MockDataContainer, forceRefresh: Bool = false) -> FoundationContext {
        if forceRefresh || isExpired {
            refreshContext(container: container)
        }
        return cached ?? FoundationContext(
            compactSchema: "ERROR: Context unavailable",
            portfolioSummary: "ERROR: No portfolio data found",
            lastUpdated: Date.distantPast
        )
    }

    public func invalidateCache() { cached = nil }

    private var isExpired: Bool {
        guard let last = cached?.lastUpdated else { return true }
        return Date().timeIntervalSince(last) > expirationInterval
    }

    private func refreshContext(container: MockDataContainer) {
        do {
            let holdings = container.holdings
            let schema = summarizeSchema(from: holdings)
            let summary = summarizePortfolio(from: holdings)
            cached = FoundationContext(
                compactSchema: schema,
                portfolioSummary: summary,
                lastUpdated: Date()
            )
        } catch {
            cached = FoundationContext(
                compactSchema: "ERROR: \(error.localizedDescription)",
                portfolioSummary: "ERROR: Summary generation failed",
                lastUpdated: Date()
            )
        }
    }

    private func summarizeSchema(from holdings: [Holding]) -> String {
        guard let first = holdings.first else { return "No holdings found." }
        // Use Mirror to introspect field names/types
        let mirror = Mirror(reflecting: first)
        let fieldLines: [String] = mirror.children.compactMap { child in
            guard let key = child.label else { return nil }
            let valueType = type(of: child.value)
            // You could add a mapping for NL hint here, or just return type as is
            return "\(key)(\(valueType))"
        }
        return "FIELDS: " + fieldLines.sorted().joined(separator: ", ")
    }

    private func summarizePortfolio(from holdings: [Holding]) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }

        let symbols = holdings.map { $0.symbol }
        let assetClasses = Set(holdings.map { $0.assetclass }).sorted()
        let regions = Set(holdings.map { $0.countryregion }).sorted()
        let accountTypes = Set(holdings.map { $0.accounttype }).sorted()
        let securityTypes = Set(holdings.map { $0.securitytype }).sorted()
        let templateTypes = Set(holdings.map { $0.assettemplatetype }).sorted()
        let currencies = Set(holdings.map { $0.sccy }).sorted()

        return """
        SYMBOLS: \(symbols.joined(separator: ","))
        ASSET CLASSES: \(assetClasses.joined(separator: ","))
        REGIONS: \(regions.joined(separator: ","))
        ACCOUNT TYPES: \(accountTypes.joined(separator: ","))
        SECURITY TYPES: \(securityTypes.joined(separator: ","))
        TEMPLATE TYPES: \(templateTypes.joined(separator: ","))
        CURRENCIES: \(currencies.joined(separator: ","))
        """
    }
}
