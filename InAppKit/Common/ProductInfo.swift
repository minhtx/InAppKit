//
//  ProductInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit

public struct ProductInfo {
    public let product: BaseProduct
    public let originalProduct: Product
    public let type: Product.ProductType
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String
    public let subscriptionInfo: SubscriptionInfo?
    
    init(_ originalProduct: Product, product: BaseProduct, subscriptionInfo: SubscriptionInfo?) {
        self.product = product
        self.originalProduct = originalProduct
        self.type = originalProduct.type
        self.displayName = originalProduct.displayName
        self.description = originalProduct.description
        self.price = originalProduct.price
        self.displayPrice = originalProduct.displayPrice
        self.subscriptionInfo = subscriptionInfo
    }
}

extension Product {
    func toProductInfo(product: BaseProduct, transactions: [Transaction]) -> ProductInfo {
        let subscriptionInfo = self.subscription?.toSubscriptionInfo(transactions: transactions)
        return ProductInfo(self, product: product, subscriptionInfo: subscriptionInfo)
    }
}
