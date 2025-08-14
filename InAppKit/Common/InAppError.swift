//
//  InAppError.swift
//  InAppKit
//
//  Created by Trinh Xuan Minh on 12/8/25.
//

import Foundation

public enum InAppError: Error {
    case unverified
    case productNotExist
    case notIntroductory
    case userCancelled
    case pending
    case unknown
    case duplicateRequest
}
