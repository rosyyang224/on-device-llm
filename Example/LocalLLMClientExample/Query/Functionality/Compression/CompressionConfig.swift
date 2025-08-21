//
//  CompressionConfig.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/21/25.
//


import Foundation

enum Compressor { }

extension Compressor {
    public struct CompressionConfig: Equatable {
        public var maxTokens: Int
        public var charsPerTokenHeuristic: Int

        public var topHoldingsCount: Int
        public var notableOtherHoldingsCount: Int

        public var recentTransactionsCount: Int
        public var transactionTypeTopCount: Int
        public var symbolTopCount: Int

        public var keepLastTrendPoints: Int
        public var includeArrays: Bool
        public var includeStats: Bool
        public var roundDecimals: Int

        public init(
            maxTokens: Int = 2000,
            charsPerTokenHeuristic: Int = 4,
            topHoldingsCount: Int = 10,
            notableOtherHoldingsCount: Int = 5,
            recentTransactionsCount: Int = 20,
            transactionTypeTopCount: Int = 5,
            symbolTopCount: Int = 7,
            keepLastTrendPoints: Int = 12,
            includeArrays: Bool = true,
            includeStats: Bool = true,
            roundDecimals: Int = 0
        ) {
            self.maxTokens = maxTokens
            self.charsPerTokenHeuristic = charsPerTokenHeuristic
            self.topHoldingsCount = topHoldingsCount
            self.notableOtherHoldingsCount = notableOtherHoldingsCount
            self.recentTransactionsCount = recentTransactionsCount
            self.transactionTypeTopCount = transactionTypeTopCount
            self.symbolTopCount = symbolTopCount
            self.keepLastTrendPoints = keepLastTrendPoints
            self.includeArrays = includeArrays
            self.includeStats = includeStats
            self.roundDecimals = roundDecimals
        }

        public static let `default` = CompressionConfig()

        public static let aggressive = CompressionConfig(
            maxTokens: 800,
            topHoldingsCount: 5,
            notableOtherHoldingsCount: 3,
            recentTransactionsCount: 10,
            transactionTypeTopCount: 4,
            symbolTopCount: 5,
            keepLastTrendPoints: 6
        )

        public static let detailed = CompressionConfig(
            maxTokens: 4000,
            topHoldingsCount: 15,
            notableOtherHoldingsCount: 8,
            recentTransactionsCount: 30,
            transactionTypeTopCount: 8,
            symbolTopCount: 10,
            keepLastTrendPoints: 24,
            roundDecimals: 2
        )
    }
}
