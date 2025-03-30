//
//  TAPurchaseServiceProtocol.swift
//  TAPPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import Foundation
import Combine

@MainActor
public protocol TAPurchaseAdaptorProtocol: Sendable {
    
    func purchaseProduct(productID: String) async throws -> [TAGrantedEntitlement]
    func restorePurchase() async throws -> [TAGrantedEntitlement]
    func getGrantedEntitlements() async throws -> [TAGrantedEntitlement]
    func getProducts(for productIDs: [String]) async throws -> [TAProduct]
    
    var grantedEntitlementsUpdatePublisher: AnyPublisher<[TAGrantedEntitlement], Never> { get }
}
