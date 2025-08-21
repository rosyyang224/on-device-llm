//
//  Fmt.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/21/25.
//

import Foundation

enum Fmt {
    static let money: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "USD"
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf
    }()
    static let intish: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf
    }()
    static let ymd: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = .init(identifier: "en_US_POSIX")
        return df
    }()
    static func usd(_ x: Double) -> String { money.string(from: x as NSNumber) ?? "$\(String(format: "%.2f", x))" }
    static func int(_ x: Double) -> String { intish.string(from: x as NSNumber) ?? String(Int(x.rounded())) }
}
