//
//  SubscriptionInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public struct SubscriptionInfo {
    public let originalSubscriptionInfo: Product.SubscriptionInfo
    public let subscriptionGroupID: String
    public let period: Product.SubscriptionPeriod
    public let offerInfos: [OfferInfo]
    public let groupDisplayName: String?
    
    init(_ originalSubscriptionInfo: Product.SubscriptionInfo) {
        self.originalSubscriptionInfo = originalSubscriptionInfo
        self.subscriptionGroupID = originalSubscriptionInfo.subscriptionGroupID
        self.period = originalSubscriptionInfo.subscriptionPeriod
        self.offerInfos = originalSubscriptionInfo.offerInfos()
        
        if #available(iOS 16.4, *) {
            self.groupDisplayName = originalSubscriptionInfo.groupDisplayName
        } else {
            self.groupDisplayName = nil
        }
    }
}

extension Product.SubscriptionInfo {
    func toSubscriptionInfo() -> SubscriptionInfo {
        return SubscriptionInfo(self)
    }
    
    func offerInfos() -> [OfferInfo] {
        var subscriptionOffers: [Product.SubscriptionOffer] = []
        
        if let introductoryOffer = self.introductoryOffer {
            subscriptionOffers.append(introductoryOffer)
        }
        
        subscriptionOffers += self.promotionalOffers
        
        if #available(iOS 18, *) {
            subscriptionOffers += self.winBackOffers
        }
        
        return subscriptionOffers.compactMap { $0.toOfferInfo(subscriptionGroupID: self.subscriptionGroupID) }
    }
}
