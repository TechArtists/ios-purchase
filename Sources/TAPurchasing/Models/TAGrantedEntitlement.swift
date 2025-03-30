//
//  TAGrantedEntitlement.swift
//  TAPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import Foundation

public struct TAGrantedEntitlement: Sendable, Identifiable {
    
    /// Unique ID for the transaction.
    public let id: String
    /// Identifies the product the transaction is for.
    public let productID: String
    /// The date this transaction occurred on.
    public let latestPurchaseDate: Date
    /// The date the original transaction for `productID` or`subscriptionGroupID` occurred on.
    public let originalPurchaseDate: Date
    /// The date the users access to `productID` expires
    /// - Note: Only for subscriptions.
    public let expirationDate: Date?
    /// Checks that entitlement is active
    public let isActive: Bool
    
    public init(id: String, productID: String, latestPurchaseDate: Date, originalPurchaseDate: Date, expirationDate: Date?, isActive: Bool) {
        self.id = id
        self.productID = productID
        self.latestPurchaseDate = latestPurchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
    
    public var eventParameters: [String: Any] {
        let dict: [String: Any?] = [
            "entitlement_id": id,
            "entitlement_productId": productID,
            "entitlement_latestPurchaseDate": latestPurchaseDate,
            "entitlement_originalPurchaseDate": originalPurchaseDate,
            "entitlement_expirationDate": expirationDate,
            "entitlement_isActive.": isActive
        ]
        return dict.compactMapValues({ $0 })
    }
}
