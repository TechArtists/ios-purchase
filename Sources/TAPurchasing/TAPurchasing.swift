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
public class TAPurchase: ObservableObject {
    
    private let service: TAPurchaseAdaptorProtocol
    private let analytics: TAAnalytics
    
    private var cancellables = Set<AnyCancellable>()
    
    public private(set) var entitlements: [TAGrantedEntitlement] = []

    private var transactionsUpdateStreamTask: Task<Void, Never>?
    
    @Published public private(set) var purchaseIsLoading: Bool = false
    
    @Published public private(set) var availableProducts: [TAProduct] = []
    
    /// Initializes a new `TAPurchase` instance.
    /// - Parameters:
    ///   - service: The purchasing service used to fetch products and handle transactions.
    ///   - analytics: Analytics tracker used to log purchasing events.
    public init(service: TAPurchaseAdaptorProtocol, analytics: TAAnalytics) {
        self.analytics = analytics
        self.service = service
    }
    
    deinit {
        transactionsUpdateStreamTask?.cancel()
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
    public func purchaseProduct( productID: String) async throws -> [TAGrantedEntitlement] {
        purchaseIsLoading = true
        
        do {
            entitlements = try await service.purchaseProduct(productID: productID)
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
        availableProducts = products
        return products
    }
    
    /// Restores previous purchases and returns the user's entitlements.
    /// - Returns: An array of granted entitlements.
    @discardableResult
    public func restorePurchase( paywall: TAPaywallAnalytics) async throws -> [TAGrantedEntitlement] {
        do {
            entitlements = try await service.restorePurchase()
            updateEntitlements(with: entitlements)
//            if let productID = entitlements.first?.productID {
//
//            }
//            analytics.trackSubscriptionRestore(
//                TASubscriptionStartAnalyticsImpl(
//                    subscriptionType: <#T##TASubscriptionType#>,
//                    paywall: paywall,
//                    productID: <#T##String#>,
//                    price: <#T##Float#>,
//                    currency: <#T##String#>
//                )
//            )
            return entitlements
        } catch {
            
            throw error
        }
    }
    
    /// Updates the local entitlements list by sorting them by expiration date.
    /// - Parameter entitlements: The updated entitlements to be stored.
    private func updateEntitlements(with entitlements: [TAGrantedEntitlement]) {
        self.entitlements = entitlements.sorted {
            ($0.expirationDate ?? .distantPast) > ($1.expirationDate ?? .distantPast)
        }
    }
}
