//
//  PermissionInfo.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 13/8/25.
//

import Foundation

public struct PermissionInfo {
    public let permission: BasePermission
    public let expiration: PermissionExpiration
    
    init(permission: BasePermission, expiration: PermissionExpiration) {
        self.permission = permission
        self.expiration = expiration
    }
}
