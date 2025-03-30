//
//  StoreKitPurchaseAdaptor.swift
//  TAPurchase
//
//  Created by Robert Tataru on 28.03.2025.
//

import StoreKit
import Foundation
import Combine

public struct StoreKitPurchaseAdaptor: TAPurchaseAdaptorProtocol {
    
    enum Error: LocalizedError {
        case productNotFound
        case userCancelledPurchase
        case failedToPurchase
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
        do {
            let products = try await Product.products(for: [productID])

            guard let product = products.first else {
                throw Error.productNotFound
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try verificationResult.payloadValue
                await transaction.finish()

                return try await getGrantedEntitlements()
            case .userCancelled:
                throw Error.userCancelledPurchase
            default:
                throw Error.failedToPurchase
            }
        } catch {
            throw error
        }
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
        return products.map({ TAProduct(storeKitProduct: $0) })
    }
}
