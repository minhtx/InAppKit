//
//  TransactionInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 18/8/25.
//

import Foundation
import StoreKit

public struct TransactionInfo {
    public let originalTransaction: Transaction
    public let id: UInt64
    public let product: BaseProduct
    public let productType: Product.ProductType
    public let price: Decimal?
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let refundedDate: Date?
    
    public var expiration: Expiration {
        return getExpiration()
    }
    
    public var isRefunded: Bool {
        return refundedDate != nil
    }
    
    init(_ originalTransaction: Transaction, product: BaseProduct) {
        self.originalTransaction = originalTransaction
        self.id = originalTransaction.id
        self.product = product
        self.productType = originalTransaction.productType
        self.price = originalTransaction.price
        self.purchaseDate = originalTransaction.purchaseDate
        self.expirationDate = originalTransaction.expirationDate
        self.refundedDate = originalTransaction.revocationDate
    }
    
    private func getExpiration() -> Expiration {
        switch originalTransaction.productType {
        case .autoRenewable:
            guard let expirationDate = originalTransaction.expirationDate, expirationDate >= Date() else {
                return .expired
            }
            return .validUntil(expirationDate)
        case .nonConsumable:
            return .lifetime
        case .nonRenewable:
            guard let duration = product.duration else {
                assertionFailure("[InAppKit] Duration not declared!")
                return .expired
            }
            let purchaseDate = originalTransaction.purchaseDate
            let expirationDate = purchaseDate.addingTimeInterval(duration)
            
            guard expirationDate >= Date() else {
                return .expired
            }
            return .validUntil(expirationDate)
        default:
            return .expired
        }
    }
}

extension Transaction {
    func toTransactionInfo(products: [BaseProduct]) -> TransactionInfo? {
        guard let product = products.first(where: { $0.id == self.productID }) else {
            assertionFailure("[InAppKit] Product not exist!")
            return nil
        }
        return TransactionInfo(self, product: product)
    }
}
