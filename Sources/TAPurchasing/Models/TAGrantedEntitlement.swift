/*
MIT License

Copyright (c) 2025 Tech Artists Agency

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//
//  TAGrantedEntitlement.swift
//  TAPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import Foundation

public struct TAGrantedEntitlement: Sendable, Identifiable {
    
    /// Unique ID for the entitlement.
    public let id: String
    /// Identifies the product the entitlement is for.
    public let productID: String
    /// The date this entitlement occurred on.
    public let latestPurchaseDate: Date?
    /// The date the original entitlement for `productID` or`subscriptionGroupID` occurred on.
    public let originalPurchaseDate: Date?
    /// The date the users access to `productID` expires
    /// - Note: Only for subscriptions.
    public let expirationDate: Date?
    /// Checks that entitlement is active
    public let isActive: Bool
    
    public init(id: String, productID: String, latestPurchaseDate: Date?, originalPurchaseDate: Date?, expirationDate: Date?, isActive: Bool) {
        self.id = id
        self.productID = productID
        self.latestPurchaseDate = latestPurchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
}
