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
    func checkTrialEligibility(productID: String) async throws -> Bool
    
    var grantedEntitlementsUpdatePublisher: AnyPublisher<[TAGrantedEntitlement], Never> { get }
}
