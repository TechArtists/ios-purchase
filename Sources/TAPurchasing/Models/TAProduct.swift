//
//  TAProduct.swift
//  TAPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import Foundation
import TAAnalytics
import StoreKit

public struct TAProduct: Identifiable, Sendable {
    
    public let id: String
    public let title: String
    public let subtitle: String
    public let price: Float
    public let displayPrice: String
    public let productDuration: ProductLifetime?
    public let currency: String
    public let storeKitProduct: Product

    public init(
        id: String,
        title: String,
        subtitle: String,
        price: Float,
        displayPrice: String,
        productDuration: ProductLifetime?,
        currency: String,
        storeKitProduct: Product
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.displayPrice = displayPrice
        self.productDuration = productDuration
        self.storeKitProduct = storeKitProduct
        self.currency = currency
    }

    public var priceStringWithDuration: String {
        if let productDuration {
            return "\(displayPrice) / \(productDuration.rawValue)"
        } else {
            return "\(displayPrice)"
        }
    }
}

public enum ProductLifetime: String, Codable, Sendable {
    case year
    case month
    case week
    case day
}
