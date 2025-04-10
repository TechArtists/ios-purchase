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
//  TAProduct+StoreKit.swift
//  TAPurchase
//
//  Created by Robert Tataru on 27.03.2025.
//

import StoreKit
import TAAnalytics

public extension TAProduct {

    init(storeKitProduct product: StoreKit.Product) {
        self.init(
            id: product.id,
            title: product.displayName,
            subtitle: product.description,
            price: Float(truncating: product.price as NSNumber),
            displayPrice: product.displayPrice,
            productDuration: ProductLifetime(unit: product.subscription?.subscriptionPeriod.unit),
            currency: "\(product.priceFormatStyle.currencyCode)",
            storeKitProduct: product
        )
    }
}

extension ProductLifetime {

    init?(unit: Product.SubscriptionPeriod.Unit?) {
        if let unit {
            switch unit {
            case .day:
                self = .day
            case .week:
                self = .week
            case .month:
                self = .month
            case .year:
                self = .year
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}

extension TASubscriptionType {
    static func determine(for product: Product, isEligibleForIntroOffer: Bool) -> TASubscriptionType {
        switch product.type {
        case .autoRenewable:
            guard let subscription = product.subscription else {
                return .other("auto-renewable-subscription-missing-info")
            }
            if let introductoryOffer = subscription.introductoryOffer {
                if isEligibleForIntroOffer {
                    switch introductoryOffer.paymentMode {
                    case .freeTrial:
                        return .trial
                    case .payAsYouGo:
                        return .paidPayAsYouGo
                    case .payUpFront:
                        return .paidPayUpFront
                    default:
                        return .other("unknown introductory offer type")
                    }
                } else {
                    return .paidRegular
                }
            } else {
                return .paidRegular
            }
        case .nonRenewable:
            return .paidPayUpFront
        case .consumable:
            return .other("consumable")
        case .nonConsumable:
            return .other("non-consumable")
        default:
            return .other("unknown product type")
        }
    }
}
