//
//  TAProduct.swift
//  TAPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import Foundation
import TAAnalytics

public struct TAProduct: Identifiable, Sendable {
    
    public let id: String
    public let title: String
    public let subtitle: String
    public let price: Decimal
    public let displayPrice: String
    public let productDuration: ProductLifetime?
    public let subscriptionType: TASubscriptionType
    public let currency: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        price: Decimal,
        displayPrice: String,
        productDuration: ProductLifetime?,
        subscriptionType: TASubscriptionType,
        currency: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.displayPrice = displayPrice
        self.productDuration = productDuration
        self.subscriptionType = subscriptionType
        self.currency = currency
    }

    public var priceStringWithDuration: String {
        if let productDuration {
            return "\(displayPrice) / \(productDuration.rawValue)"
        } else {
            return "\(displayPrice)"
        }
    }

    public var eventParameters: [String: Any] {
        let dict: [String: Any?] = [
            "product_id": id,
            "product_title": title,
            "product_subtitle": subtitle,
            "product_price_string": displayPrice,
            "product_product_duration": productDuration?.rawValue,
            "product_currency": currency
        ]
        return dict.compactMapValues { $0 }
    }
}

public enum ProductLifetime: String, Codable, Sendable {
    case year
    case month
    case week
    case day
}
