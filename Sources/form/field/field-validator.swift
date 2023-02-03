//
//  File.swift
//  
//
//  Created by Michael Ong on 2/3/23.
//

import Foundation

public struct FieldValidator<Value> {
    public let validate: (Value) throws -> Void

    public init(validate: @escaping (Value) throws -> Void) {
        self.validate = validate
    }
}
