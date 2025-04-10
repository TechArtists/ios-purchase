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
//  TAPurchase.swift
//  TAPurchase
//
//  Created by Robert Tataru on 11/11/24.
//

import Foundation
import TAAnalytics
import Combine

@MainActor
open class TAPurchase: ObservableObject {
    
    private let service: TAPurchaseAdaptorProtocol
    private let analytics: TAAnalytics
    
    open var cancellables = Set<AnyCancellable>()
    
    @Published public private(set) var entitlements: [TAGrantedEntitlement] = []
    
    @Published public private(set) var purchaseIsLoading: Bool = false
    
    /// Initializes a new `TAPurchase` instance.
    /// - Parameters:
    ///   - service: The purchasing service used to fetch products and handle transactions.
    ///   - analytics: Analytics tracker used to log purchasing events.
    public init(service: TAPurchaseAdaptorProtocol, analytics: TAAnalytics) {
        self.analytics = analytics
        self.service = service
    }
    
    /// Starts listening for transaction updates and automatically updates entitlements.
    public func start() {
        service.grantedEntitlementsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entitlements in
                self?.updateEntitlements(with: entitlements)
            }
            .store(in: &cancellables)
    }
    
    /// Purchases a product and returns the updated user entitlements.
    /// - Parameter productID: The identifier of the product to purchase.
    /// - Returns: An array of updated granted entitlements.
    @discardableResult
    public func purchaseProduct( productID: String, paywall: TAPaywallAnalytics) async throws -> [TAGrantedEntitlement] {
        purchaseIsLoading = true
        
        do {
            entitlements = try await service.purchaseProduct(productID: productID)
            if let product = try await service.getProducts(for: [productID]).first {
                let isEligible = try await checkTrialEligibility(productID: productID)
                trackSubscriptionStart(for: product, paywall: paywall, isEligibleForIntroOffer: isEligible)
            }
            purchaseIsLoading = false
            return entitlements
        } catch {
            purchaseIsLoading = false
            throw error
        }
    }
    
    /// Fetches available products that can be purchased.
    /// - Parameter productIDs: An array of product identifiers to query.
    /// - Returns: An array of `TAProduct` objects.
    public func getProducts( productIDs: [String]) async throws -> [TAProduct] {
        let products = try await service.getProducts(for: productIDs)
        return products
    }
    
    /// Checks if Product with `productID` is eligible for trial
    /// - Parameter productID: The product identifier.
    public func checkTrialEligibility(productID: String) async throws -> Bool {
        try await service.checkTrialEligibility(productID: productID)
    }
    
    /// Restores previous purchases and returns the user's entitlements.
    /// - Returns: An array of granted entitlements.
    @discardableResult
    public func restorePurchase( paywall: TAPaywallAnalytics) async throws -> [TAGrantedEntitlement] {
        entitlements = try await service.restorePurchase()
        updateEntitlements(with: entitlements)
        
        if let productID = entitlements.first?.productID {
            let products = try await getProducts(productIDs: [productID])
            guard let product = products.first else { return entitlements }
            
            let isEligibleForIntroOffer = try await checkTrialEligibility(productID: productID)
            let subscriptionType = TASubscriptionType.determine(for: product.storeKitProduct, isEligibleForIntroOffer: isEligibleForIntroOffer)

            analytics.trackSubscriptionRestore(
                TASubscriptionStartAnalyticsImpl(
                    subscriptionType: subscriptionType,
                    paywall: paywall,
                    productID: product.id,
                    price: Float(product.price),
                    currency: product.currency
                )
            )
        }
        return entitlements
    }
    
    private func updateEntitlements(with entitlements: [TAGrantedEntitlement]) {
        self.entitlements = entitlements.sorted {
            ($0.expirationDate ?? .distantPast) > ($1.expirationDate ?? .distantPast)
        }
    }
    
    private func trackSubscriptionStart(for product: TAProduct, paywall: TAPaywallAnalytics, isEligibleForIntroOffer: Bool) {
        
        let subscriptionType = TASubscriptionType.determine(for: product.storeKitProduct, isEligibleForIntroOffer: isEligibleForIntroOffer)

        let event = TASubscriptionStartAnalyticsImpl(
            subscriptionType: subscriptionType,
            paywall: paywall,
            productID: product.id,
            price: Float(product.price),
            currency: product.currency
        )

        switch subscriptionType {
        case .paidRegular:
            analytics.trackSubscriptionStartPaidRegular(event)
        case .trial, .paidPayAsYouGo, .paidPayUpFront:
            analytics.trackSubscriptionStartIntro(event)
        default:
            break
        }
    }
}
