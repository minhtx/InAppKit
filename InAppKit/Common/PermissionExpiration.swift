//
//  PermissionExpiration.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 13/8/25.
//

import Foundation

public enum PermissionExpiration {
    case lifetime
    case expires(on: Date)
}

extension PermissionExpiration {
    static func max(_ a: Self, _ b: Self) -> Self {
        switch (a, b) {
        case (.lifetime, _):
            return .lifetime
        case (_, .lifetime):
            return .lifetime
        case let (.expires(dateA), .expires(dateB)):
            return dateA > dateB ? a : b
        }
    }
}
