//
//  ProductInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public struct ProductInfo {
    public let id: String
    public let originalProduct: Product
    public let type: Product.ProductType
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String
    public let subscriptionInfo: SubscriptionInfo?
    
    init(_ product: Product, subscriptionInfo: SubscriptionInfo?) {
        self.id = product.id
        self.originalProduct = product
        self.type = product.type
        self.displayName = product.displayName
        self.description = product.description
        self.price = product.price
        self.displayPrice = product.displayPrice
        self.subscriptionInfo = subscriptionInfo
    }
}

extension Product {
    func toProductInfo(transactions: [Transaction]) -> ProductInfo {
        let subscriptionInfo = self.subscription?.toSubscriptionInfo(transactions: transactions)
        return ProductInfo(self, subscriptionInfo: subscriptionInfo)
    }
}
