//
//  OfferInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public struct OfferInfo {
    public let originalOffer: Product.SubscriptionOffer
    public let paymentMode: Product.SubscriptionOffer.PaymentMode
    public let subscriptionGroupID: String
    public let id: String?
    public let type: Product.SubscriptionOffer.OfferType
    public let price: Decimal?
    public let displayPrice: String?
    public let period: Product.SubscriptionPeriod?
    public let periodCount: Int?
    
    init(_ originalOffer: Product.SubscriptionOffer, subscriptionGroupID: String) {
        self.originalOffer = originalOffer
        self.paymentMode = originalOffer.paymentMode
        self.subscriptionGroupID = subscriptionGroupID
        self.id = originalOffer.id
        self.type = originalOffer.type
        self.price = originalOffer.price
        self.displayPrice = originalOffer.displayPrice
        self.period = originalOffer.period
        self.periodCount = originalOffer.periodCount
    }
}

extension Product.SubscriptionOffer {
    func toOfferInfo(subscriptionGroupID: String) -> OfferInfo {
        return OfferInfo(self, subscriptionGroupID: subscriptionGroupID)
    }
}

extension Product.SubscriptionOffer.OfferType {
    init?(transactionOfferType: Transaction.OfferType?) {
        guard let type = transactionOfferType else {
            return nil
        }
        switch type {
        case .introductory:
            self = .introductory
        case .promotional:
            self = .promotional
        case .winBack:
            if #available(iOS 18.0, *) {
                self = .winBack
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
