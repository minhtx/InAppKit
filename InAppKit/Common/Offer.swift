//
//  IntroductoryOffer.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public enum Offer {
    case freeTrial(info: FreeTrialOfferInfo)
    case payAsYouGo(info: PayAsYouGoOfferInfo)
    case payUpFront(info: PayUpFrontOfferInfo)
    
    public struct FreeTrialOfferInfo {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let period: Product.SubscriptionPeriod
        public let eligibility: OfferEligibility
        
        init(_ subscriptionOffer: Product.SubscriptionOffer, eligibility: OfferEligibility) {
            self.id = subscriptionOffer.id
            self.type = subscriptionOffer.type
            self.period = subscriptionOffer.period
            self.eligibility = eligibility
        }
    }
    
    public struct PayAsYouGoOfferInfo {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let price: Decimal
        public let displayPrice: String
        public let period: Product.SubscriptionPeriod
        public let periodCount: Int
        public let eligibility: OfferEligibility
        
        init(_ subscriptionOffer: Product.SubscriptionOffer, eligibility: OfferEligibility) {
            self.id = subscriptionOffer.id
            self.type = subscriptionOffer.type
            self.price = subscriptionOffer.price
            self.displayPrice = subscriptionOffer.displayPrice
            self.period = subscriptionOffer.period
            self.periodCount = subscriptionOffer.periodCount
            self.eligibility = eligibility
        }
    }
    
    public struct PayUpFrontOfferInfo {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let price: Decimal
        public let displayPrice: String
        public let period: Product.SubscriptionPeriod
        public let eligibility: OfferEligibility
        
        init(_ subscriptionOffer: Product.SubscriptionOffer, eligibility: OfferEligibility) {
            self.id = subscriptionOffer.id
            self.type = subscriptionOffer.type
            self.price = subscriptionOffer.price
            self.displayPrice = subscriptionOffer.displayPrice
            self.period = subscriptionOffer.period
            self.eligibility = eligibility
        }
    }
}

extension Product.SubscriptionOffer {
    func toOffer(eligibility: OfferEligibility) -> Offer? {
        switch paymentMode {
        case .freeTrial:
            return .freeTrial(info: Offer.FreeTrialOfferInfo(self, eligibility: eligibility))
        case .payAsYouGo:
            return .payAsYouGo(info: Offer.PayAsYouGoOfferInfo(self, eligibility: eligibility))
        case .payUpFront:
            return .payUpFront(info: Offer.PayUpFrontOfferInfo(self, eligibility: eligibility))
        default:
            return nil
        }
    }
    
    func eligibility(groupTransactions: [Transaction]) -> OfferEligibility {
        let offerType = self.type
        
        for transaction in groupTransactions {
            switch offerType {
            case .introductory:
                if transaction.offerType == .introductory {
                    return .ineligible
                }
            default:
                guard #available(iOS 17.2, *) else {
                    return .unknown
                }
                if let transactionOffer = transaction.offer,
                   let mappedType = Product.SubscriptionOffer.OfferType(transactionOfferType: transactionOffer.type),
                   mappedType == offerType,
                   let offerID = self.id,
                   offerID == transactionOffer.id
                {
                    return .ineligible
                }
            }
        }
        return .eligible
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
        default: return nil
        }
    }
}
