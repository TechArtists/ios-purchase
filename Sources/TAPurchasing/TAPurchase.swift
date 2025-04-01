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
        do {
            entitlements = try await service.restorePurchase()
            updateEntitlements(with: entitlements)
            
            if let productID = entitlements.first?.productID {
                let products = try await getProducts(productIDs: [productID])
                guard let product = products.first else { return entitlements }

                analytics.trackSubscriptionRestore(
                    TASubscriptionStartAnalyticsImpl(
                        subscriptionType: product.subscriptionType,
                        paywall: paywall,
                        productID: product.id,
                        price: Float(product.price),
                        currency: product.currency
                    )
                )
            }
            return entitlements
        } catch {
            throw error
        }
    }
    
    private func updateEntitlements(with entitlements: [TAGrantedEntitlement]) {
        self.entitlements = entitlements.sorted {
            ($0.expirationDate ?? .distantPast) > ($1.expirationDate ?? .distantPast)
        }
    }
    
    private func trackSubscriptionStart(for product: TAProduct, paywall: TAPaywallAnalytics, isEligibleForIntroOffer: Bool) {

        let event = TASubscriptionStartAnalyticsImpl(
            subscriptionType: product.subscriptionType,
            paywall: paywall,
            productID: product.id,
            price: Float(product.price),
            currency: product.currency
        )

        switch product.subscriptionType {
        case .paidRegular:
            analytics.trackSubscriptionStartPaidRegular(event)
        case .trial, .paidPayAsYouGo, .paidPayUpFront:
            analytics.trackSubscriptionStartIntro(event)
        default:
            break
        }
    }
}
