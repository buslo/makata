// field-validator.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public struct FieldValidator<Shape, Value> {
    public let validate: (Shape, Value) throws -> Void
    
    public let propagates: Bool

    public init(propagates: Bool = true, validate: @escaping (Shape, Value) throws -> Void) {
        self.validate = validate
        self.propagates = propagates
    }
    
    public init(propagates: Bool = true, validate: @escaping (Value) throws -> Void) {
        self.validate = { _, value throws in
            try validate(value)
        }
        self.propagates = propagates
    }
}
