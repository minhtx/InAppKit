//
//  BasePermission.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation

public protocol BasePermission {
    var id: String { get }
    var products: [BaseProduct] { get }
}
