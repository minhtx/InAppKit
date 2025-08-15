//
//  PermissionInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 13/8/25.
//

import Foundation

public struct PermissionInfo {
    public let originalPermission: BasePermission
    public let expiration: PermissionExpiration
    
    init(originalPermission: BasePermission, expiration: PermissionExpiration) {
        self.originalPermission = originalPermission
        self.expiration = expiration
    }
}
