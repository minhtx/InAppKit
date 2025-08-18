//
//  Expiration.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 13/8/25.
//

import Foundation

public enum Expiration: Equatable {
    case lifetime
    case expires(on: Date)
    case unknown
}

extension Expiration {
    static func max(_ a: Self, _ b: Self) -> Self {
        switch (a, b) {
        case (.lifetime, _), (_, .lifetime):
            return .lifetime
        case let (.expires(dateA), .expires(dateB)):
            return dateA > dateB ? a : b
        case (.expires, .unknown):
            return a
        case (.unknown, .expires):
            return b
        case (.unknown, .unknown):
            return .unknown
        }
    }
}
