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
            price: product.price,
            displayPrice: product.displayPrice,
            productDuration: ProductLifetime(unit: product.subscription?.subscriptionPeriod.unit),
            subscriptionType: .from(storeKitProduct: product),
            currency: "\(product.priceFormatStyle.currencyCode)"
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
    static func from(storeKitProduct product: StoreKit.Product) -> TASubscriptionType {
        switch product.type {
        case .autoRenewable:
            if let subscription = product.subscription {
                if let introductoryOffer = subscription.introductoryOffer {
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
                return .other("auto-renewable subscription missing info")
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
