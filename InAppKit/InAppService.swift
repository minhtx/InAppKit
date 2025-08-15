//
//  InAppService.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation
import StoreKit
import Combine

@available(iOS 15, *)
public protocol InAppServiceType: AnyObject {
    var permissionsSubject: CurrentValueSubject<[PermissionInfo], Never> { get }
    var isPurchasingSubject: CurrentValueSubject<Bool, Never> { get }
    
    func retrieveInfo(_ product: BaseProduct) async throws -> ProductInfo
    func retrieveInfo(_ products: [BaseProduct]) async throws -> [ProductInfo]
    func history() async -> [Transaction]
    func purchase(_ product: BaseProduct) async throws -> ProductInfo
    func restore() async
    @MainActor func requestRefund(for transaction: Transaction, in scene: UIWindowScene) async throws -> Transaction
}

@available(iOS 15, *)
public final class InAppService: InAppServiceType {
    public var permissionsSubject = CurrentValueSubject<[PermissionInfo], Never>([])
    public var isPurchasingSubject = CurrentValueSubject<Bool, Never>(false)
    
    private let products: [BaseProduct]
    private let permissions: [BasePermission]
    private var expiryCheckTask: Task<Void, Never>?
    
    public init(products: [BaseProduct], permissions: [BasePermission]) {
        self.products = products
        self.permissions = permissions
        
        requestPermissions()
        observeTransactions()
        startExpiryCheckLoop()
        addObserver()
    }
    
    deinit {
        stopExpiryCheckLoop()
        NotificationCenter.default.removeObserver(self)
        print("[InAppKit] Deinit!")
    }
}

extension InAppService {
    private static var _sharedInstance: InAppService?
    
    public static var sharedInstance: InAppService {
        guard let instance = _sharedInstance else {
            fatalError("InAppService is not configured yet. Call configure configureShared() first.")
        }
        return instance
    }
    
    public static func configureShared(with products: [BaseProduct], permissions: [BasePermission]) {
        _sharedInstance = InAppService(products: products, permissions: permissions)
    }
}

extension InAppService {
    public func retrieveInfo(_ product: BaseProduct) async throws -> ProductInfo {
        print("[InAppKit] Start getting product information! - \(product)")
        let productIDs = [product.id]
        let originalProducts = try await Product.products(for: productIDs)
        
        guard let originalProduct = originalProducts.first else {
            throw InAppError.productNotExist
        }
        
        let verifiedTransaction = await getVerifiedTransaction()
        
        let productInfo = originalProduct.toProductInfo(product: product, transactions: verifiedTransaction)
        print("[InAppKit] Product information retrieved! - \(product)")
        return productInfo
    }
    
    public func retrieveInfo(_ products: [BaseProduct]) async throws -> [ProductInfo] {
        print("[InAppKit] Start getting products information! - \(products)")
        let productIDs = products.map((\.id))
        let originalProducts = try await Product.products(for: productIDs)
        
        let verifiedTransaction = await getVerifiedTransaction()
        
        let productDictionary = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let productInfos: [ProductInfo] = originalProducts.compactMap { originalProduct in
            guard let baseProduct = productDictionary[originalProduct.id] else {
                return nil
            }
            return originalProduct.toProductInfo(product: baseProduct, transactions: verifiedTransaction)
        }
        print("[InAppKit] Products information retrieved! - \(products)")
        return productInfos
    }
    
    public func history() async -> [Transaction] {
        print("[InAppKit] Retrieving history!")
        let verifiedTransaction = await getVerifiedTransaction()
        
        if verifiedTransaction.isEmpty {
            print("[InAppKit] No history!")
        } else {
            print("[InAppKit] History returned!")
        }
        return verifiedTransaction
    }
    
    public func purchase(_ product: BaseProduct) async throws -> ProductInfo {
        print("[InAppKit] Purchasing! - \(product)")
        self.isPurchasingSubject.send(true)
        
        let productIDs = [product.id]
        let originalProducts = try await Product.products(for: productIDs)
        
        guard let originalProduct = originalProducts.first else {
            self.isPurchasingSubject.send(false)
            throw InAppError.productNotExist
        }
        
        let result = try await originalProduct.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                
                await updatePermissions()
                
                let verifiedTransaction = await getVerifiedTransaction()
                let productInfo = originalProduct.toProductInfo(product: product, transactions: verifiedTransaction)
                print("[InAppKit] Purchased! - \(product)")
                self.isPurchasingSubject.send(false)
                return productInfo
            case .unverified:
                print("[InAppKit] Unverified! - \(product)")
                self.isPurchasingSubject.send(false)
                throw InAppError.unverified
            }
        case .userCancelled:
            print("[InAppKit] User cancelled! - \(product)")
            self.isPurchasingSubject.send(false)
            throw InAppError.userCancelled
        case .pending:
            print("[InAppKit] Pending! - \(product)")
            self.isPurchasingSubject.send(false)
            throw InAppError.pending
        @unknown default:
            print("[InAppKit] Unknown error! - \(product)")
            self.isPurchasingSubject.send(false)
            throw InAppError.unknown
        }
    }
    
    public func restore() async {
        print("[InAppKit] Restoring!")
        var transactionPermissions = [PermissionInfo]()
        
        for await verification in Transaction.all {
            guard case .verified(let transaction) = verification else {
                continue
            }
            let permissions = getPermissions(transaction)
            transactionPermissions += permissions
        }
        let mergePermissions = mergePermissions(transactionPermissions)
        
        await MainActor.run { [weak self] in
            guard let self else {
                return
            }
            self.permissionsSubject.send(mergePermissions)
            print("[InAppKit] Restored!")
        }
    }
    
    @MainActor
    public func requestRefund(for transaction: Transaction, in scene: UIWindowScene) async throws -> Transaction {
        do {
            let status = try await transaction.beginRefundRequest(in: scene)
            
            switch status {
            case .success:
                print("[InAppKit] Refund request sheet presented!")
                return transaction
            case .userCancelled:
                print("[InAppKit] User cancelled refund request!")
                throw InAppError.userCancelled
            @unknown default:
                print("[InAppKit] Unknown refund request status!")
                throw InAppError.unknown
            }
        } catch let refundError as Transaction.RefundRequestError {
            switch refundError {
            case .duplicateRequest:
                throw InAppError.duplicateRequest
            default:
                throw InAppError.unknown
            }
        }
    }
}

extension InAppService {
    private func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        startExpiryCheckLoop()
    }
    
    @objc private func appWillResignActive() {
        stopExpiryCheckLoop()
    }
}

extension InAppService {
    private func getVerifiedTransaction() async -> [Transaction] {
        var transactions: [Transaction] = []
        
        for await result in Transaction.all {
            guard case .verified(let transaction) = result else {
                continue
            }
            transactions.append(transaction)
        }
        return transactions
    }
    
    private func requestPermissions() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else {
                return
            }
            await self.updatePermissions()
        }
    }
    
    private func observeTransactions() {
        Task.detached(priority: .background) { [weak self] in
            for await verification in Transaction.updates {
                guard let self else {
                    return
                }
                guard case .verified(let transaction) = verification else {
                    continue
                }
                await self.updatePermissions()
                await transaction.finish()
            }
        }
    }
    
    private func updatePermissions() async {
        print("[InAppKit] Updating permissions!")
        var transactionPermissions = [PermissionInfo]()
        
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else {
                continue
            }
            let permissions = getPermissions(transaction)
            transactionPermissions += permissions
        }
        let mergePermissions = mergePermissions(transactionPermissions)
        
        await MainActor.run { [weak self] in
            guard let self else {
                return
            }
            self.permissionsSubject.send(mergePermissions)
            print("[InAppKit] Finished permissions update!")
        }
    }
    
    private func getPermissions(_ transaction: Transaction) -> [PermissionInfo] {
        guard transaction.productType != .consumable else {
            return []
        }
        guard transaction.revocationDate == nil else {
            return []
        }
        guard !permissions.isEmpty else {
            assertionFailure("[InAppKit] Empty permissions!")
            return []
        }
        guard !products.isEmpty else {
            assertionFailure("[InAppKit] Empty products!")
            return []
        }
        guard let product = products.first(where: { $0.id == transaction.productID }) else {
            assertionFailure("[InAppKit] Product not exist!")
            return []
        }
        
        let expiration: PermissionExpiration
        switch transaction.productType {
        case .autoRenewable:
            guard let expirationDate = transaction.expirationDate, expirationDate >= Date() else {
                return []
            }
            expiration = .expires(on: expirationDate)
        case .nonConsumable:
            expiration = .lifetime
        case .nonRenewable:
            guard let duration = product.duration else {
                assertionFailure("[InAppKit] Duration not declared!")
                return []
            }
            let purchaseDate = transaction.purchaseDate
            let expirationDate = purchaseDate.addingTimeInterval(duration)
            
            guard expirationDate >= Date() else {
                return []
            }
            expiration = .expires(on: expirationDate)
        default:
            return []
        }
        
        return permissions.filter { permission in
            return permission.products.contains { product in
                return product.id == transaction.productID
            }
        }.map { permission in
            return PermissionInfo(originalPermission: permission,
                                  expiration: expiration)
        }
    }
    
    private func mergePermissions(_ permissions: [PermissionInfo]) -> [PermissionInfo] {
        var dict: [String: PermissionInfo] = [:]
        
        for permissionInfo in permissions {
            let id = permissionInfo.originalPermission.id
            let expiration = permissionInfo.expiration
            
            if let existing = dict[id] {
                dict[id] = PermissionInfo(originalPermission: existing.originalPermission,
                                          expiration: PermissionExpiration.max(existing.expiration, expiration))
            } else {
                dict[id] = PermissionInfo(originalPermission: permissionInfo.originalPermission,
                                          expiration: expiration)
            }
        }
        
        return dict.map { $0.value }
    }
    
    private func startExpiryCheckLoop() {
        print("[InAppKit] Start expiry check loop!")
        self.expiryCheckTask?.cancel()
        self.expiryCheckTask = Task.detached(priority: .background) { [weak self] in
            let expiryCheckInterval: TimeInterval = 30
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(expiryCheckInterval * 1_000_000_000))
                
                guard let self = self else {
                    return
                }
                print("[InAppKit] Expiry check!")
                
                var shouldUpdate = false
                let permissions = self.permissionsSubject.value
                
                for permission in permissions {
                    if case .expires(let date) = permission.expiration, date < Date() {
                        shouldUpdate = true
                        break
                    }
                }
                
                if shouldUpdate {
                    print("[InAppKit] Permission expired!")
                    await self.updatePermissions()
                }
            }
        }
    }
    
    private func stopExpiryCheckLoop() {
        print("[InAppKit] Stop expiry check loop!")
        expiryCheckTask?.cancel()
        self.expiryCheckTask = nil
    }
}
