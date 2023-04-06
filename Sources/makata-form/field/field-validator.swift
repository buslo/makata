// field-validator.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 An object to define a validation constraint.
 
 The `FieldValidator` class is generic over a `Shape` type, which represents the shape of the form data that it will validate and a `Value` type, which represents the value of the field that will be validated. The Shape type is expected to be a `struct` and the Value type can be anything.
 
 To validate a field, you can directly initialize this object:
 
 ```swift
 FormValidation().validations(for: \.name, are: .init { value in
    guard !value.isEmpty else {
        throw FieldError.invalid("is empty.")
        return
    }
 })
 
 ```
 
 But the better and more scalable way is to create a `struct` that will do the validation:
 
 ```swift
 extension FieldValidator where Value == String {
    var notEmpty: FieldValidator {
        .init { value in
            guard !value.isEmpty else {
                throw FieldError.invalid("is empty.")
                return
            }
        }
    }
 }
 
 // and using it
 FormValidation().validations(for: \.name, are: .notEmpty)
 
 ```
 
 - remark: Makata Form does not include premade `FieldValidator`s to allow consuming applications to have their own
 naming conventions.
 
 */
public struct FieldValidator<Shape, Value> {
    internal let validate: (Shape, Value) throws -> Void

    internal let propagates: Bool

    /**
     Creates a new field validator, with reference to the current recorded form data.
     
     - parameter propagates: Set to `true` if you want to check for succeeding validation constraint if this constraint failed.
     - parameter validate: Closure to do validations.
     */
    public init(propagates: Bool = true, validate: @escaping (Shape, Value) throws -> Void) {
        self.validate = validate
        self.propagates = propagates
    }

    /**
     Creates a new field validator.
     
     - parameter propagates: Set to `true` if you want to check for succeeding validation constraint if this constraint failed.
     - parameter validate: Closure to do validations.
     */
    public init(propagates: Bool = true, validate: @escaping (Value) throws -> Void) {
        self.validate = { _, value throws in
            try validate(value)
        }
        self.propagates = propagates
    }
}
