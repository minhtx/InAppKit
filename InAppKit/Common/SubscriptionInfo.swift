//
//  SubscriptionInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public struct SubscriptionInfo {
    public let groupID: String
    public let period: Product.SubscriptionPeriod
    public let offers: [Offer]
    public let groupDisplayName: String?
    
    init(_ subscription: Product.SubscriptionInfo, offers: [Offer]) {
        self.groupID = subscription.subscriptionGroupID
        self.period = subscription.subscriptionPeriod
        self.offers = offers
        
        if #available(iOS 16.4, *) {
            self.groupDisplayName = subscription.groupDisplayName
        } else {
            self.groupDisplayName = nil
        }
    }
}

extension Product.SubscriptionInfo {
    func toSubscriptionInfo(transactions: [Transaction]) -> SubscriptionInfo {
        let offers = offers(transactions: transactions)
        return SubscriptionInfo(self, offers: offers)
    }
    
    func offers(transactions: [Transaction]) -> [Offer] {
        var subscriptionOffers: [Product.SubscriptionOffer] = []
        
        if let introductoryOffer = self.introductoryOffer {
            subscriptionOffers.append(introductoryOffer)
        }
        
        subscriptionOffers += self.promotionalOffers
        
        if #available(iOS 18, *) {
            subscriptionOffers += self.winBackOffers
        }
        
        let groupTransactions = transactions.filter { $0.subscriptionGroupID == self.subscriptionGroupID }
        
        return subscriptionOffers.compactMap { subscriptionOffer in
            let eligibility = subscriptionOffer.eligibility(groupTransactions: groupTransactions)
            return subscriptionOffer.toOffer(eligibility: eligibility)
        }
    }
}
