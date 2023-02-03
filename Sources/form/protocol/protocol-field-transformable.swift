//
//  File.swift
//  
//
//  Created by Michael Ong on 2/3/23.
//

import Foundation

public protocol FieldTransformable {
    associatedtype Value
    associatedtype Output

    func encode(to value: Value) throws -> Output
    func decode(from value: Output) throws -> Value
}
