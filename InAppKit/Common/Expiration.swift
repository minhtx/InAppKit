//
//  Expiration.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 13/8/25.
//

import Foundation

public enum Expiration: Equatable {
    case lifetime
    case validUntil(Date)
    case expired
}

extension Expiration {
    static func max(_ a: Self, _ b: Self) -> Self {
        switch (a, b) {
        case (.lifetime, _), (_, .lifetime):
            return .lifetime
        case let (.validUntil(dateA), .validUntil(dateB)):
            return dateA > dateB ? a : b
        case (.validUntil, .expired):
            return a
        case (.expired, .validUntil):
            return b
        case (.expired, .expired):
            return .expired
        }
    }
}
