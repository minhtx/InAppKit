//
//  BaseProduct.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation

public protocol BaseProduct {
    var id: String { get }
    var value: [String: Any]? { get }
}
