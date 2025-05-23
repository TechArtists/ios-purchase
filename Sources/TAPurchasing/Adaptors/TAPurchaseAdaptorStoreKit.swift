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
//  StoreKitPurchaseAdaptor.swift
//  TAPurchase
//
//  Created by Robert Tataru on 28.03.2025.
//

import StoreKit
import Foundation
import Combine

public struct TAPurchaseAdaptorStoreKit: TAPurchaseAdaptorProtocol {
    
    enum PurchaseError: LocalizedError {
        case productNotFound
        case userCancelledPurchase
        case failedToPurchase
        case pending
        case successUnverified(Error)
    }
    
    public var grantedEntitlementsUpdatePublisher: AnyPublisher<[TAGrantedEntitlement], Never>
    
    private let entitlementsSubject = PassthroughSubject<[TAGrantedEntitlement], Never>()
    
    init() {
        self.grantedEntitlementsUpdatePublisher = entitlementsSubject.eraseToAnyPublisher()

        start()
    }
    
    private func start() {
        Task {
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    if let entitlements = try? await self.getGrantedEntitlements() {
                        entitlementsSubject.send(entitlements)
                    }

                    await transaction.finish()
                }
            }
        }
    }
    
    public func purchaseProduct(productID: String) async throws -> [TAGrantedEntitlement] {
        let products = try await Product.products(for: [productID])

        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            return try await getGrantedEntitlements()
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            throw PurchaseError.successUnverified(error)
        case .pending:
            // Transaction waiting on SCA or approval from Ask to Buy
            throw PurchaseError.pending
        case .userCancelled:
            throw PurchaseError.userCancelledPurchase
        @unknown default:
            throw PurchaseError.failedToPurchase
        }
    }
    
    public func checkTrialEligibility(productID: String) async throws -> Bool {
        let products = try await Product.products(for: [productID])
        
        guard let product = products.first, let subscriptionInfo = product.subscription else {
            throw PurchaseError.productNotFound
        }
        
        let eligibility = await subscriptionInfo.isEligibleForIntroOffer
        return eligibility
    }
    
    public func restorePurchase() async throws -> [TAGrantedEntitlement] {
        try await AppStore.sync()
        return try await getGrantedEntitlements()
    }
    
    public func getGrantedEntitlements() async throws -> [TAGrantedEntitlement] {
        var allEntitlements = [TAGrantedEntitlement]()

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                let isActive: Bool = {
                    if let expirationDate = transaction.expirationDate {
                        return expirationDate >= Date()
                    }
                    return transaction.revocationDate == nil
                }()
                
                allEntitlements.append(
                    .init(
                        id: "\(transaction.id)",
                        productID: transaction.productID,
                        latestPurchaseDate: transaction.purchaseDate,
                        originalPurchaseDate: transaction.originalPurchaseDate,
                        expirationDate: transaction.expirationDate,
                        isActive: isActive
                    )
                )
            case .unverified:
                break
            }
        }

        return allEntitlements
    }
    
    public func getProducts(for productIDs: [String]) async throws -> [TAProduct] {
        let products = try await Product.products(for: productIDs)
        
        return try await withThrowingTaskGroup(of: TAProduct.self) { group in
            for product in products {
                group.addTask {
                    return TAProduct(storeKitProduct: product)
                }
            }
            
            var results: [TAProduct] = []
            for try await taProduct in group {
                results.append(taProduct)
            }
            return results
        }
    }
}
