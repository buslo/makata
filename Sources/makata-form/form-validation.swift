// form-validation.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 Builder object to define form field validation.
 
 The `FormValidation` class is generic over a `Shape` type, which represents the shape of the form data that it will validate. The Shape type is expected to be a `struct`, and each property of the `Shape` type represents a field that would be validated.
 */
public struct FormValidation<Shape> {
    
    /**
     The result of the validation.
     */
    public struct Result {
        /// Value to check if there are no validation errors produced.
        public static var noErrors: Result { Result(fields: [:]) }

        /// The fields that has validation errors.
        public let fields: [PartialKeyPath<Shape>: [Error]]
    }

    let validationsDict: [PartialKeyPath<Shape>: (Shape) -> [Error]]

    /**
     Create a new validation builder.
     */
    public init() {
        validationsDict = [:]
    }

    init(_ newDict: [PartialKeyPath<Shape>: (Shape) -> [Error]]) {
        validationsDict = newDict
    }

    /**
     Define validations for a field.
     
     - parameter path: The field path to validate.
     - parameter fields: The constraints the validator would be using for this field.
     
     The `fields` parameter is variadic so you can add more than one validation constraint.
     
     Do note that calling this method a second time will override all previously defined constraints.
     
     */
    public func validations<Value>(
        for path: KeyPath<Shape, Value>,
        are fields: FieldValidator<Shape, Value>...
    ) -> Self {
        if validationsDict[path] != nil {
            fatalError("Appending additional validations for path not allowed.")
        }

        var newDict = validationsDict
        newDict[path] = { shape in
            var fieldErrors = [Error]()

            for field in fields {
                do {
                    try field.validate(shape, shape[keyPath: path])
                } catch {
                    fieldErrors.append(error)

                    if !field.propagates {
                        break
                    }
                }
            }

            return fieldErrors
        }

        return .init(newDict)
    }

    /**
     Define validations for a partial value field.
     
     - parameter path: The field path to validate.
     - parameter fields: The constraints the validator would be using for this field.
     
     The `fields` parameter is variadic so you can add more than one validation constraint.
     
     Do note that calling this method a second time will override all previously defined constraints.
     
     - remark: The validator will fail immediately with error `FieldError.incomplete` if the recoded value is `.partial`.
     */
    public func validations<Value>(
        for path: KeyPath<Shape, FieldPartialValue<Value, some Any>>,
        are fields: FieldValidator<Shape, Value>...
    ) -> Self {
        var newDict = validationsDict
        newDict[path] = { shape in
            var fieldErrors = [Error]()

            fields.forEach { field in
                do {
                    switch shape[keyPath: path] {
                    case let .complete(complete):
                        try field.validate(shape, complete)
                    case let .partial(_, error):
                        throw FieldError.incomplete(error)
                    }
                } catch {
                    fieldErrors.append(error)
                }
            }

            return fieldErrors
        }

        return .init(newDict)
    }

    /**
     
     Called to perform validations over an object
     
     - parameter shape: The object to validate against.
     
     - returns: The validation result.
     */
    public func validate(_ shape: Shape) -> Result {
        let errors = validationsDict.compactMap { key, value in
            let fieldErrors = value(shape)

            if !fieldErrors.isEmpty {
                return (key, fieldErrors)
            } else {
                return nil
            }
        }

        return .init(fields: .init(uniqueKeysWithValues: errors))
    }
}

public extension FormValidation {
    #if swift(<5.8)
        func validations<Value>(
            for path: KeyPath<Shape, Value?>,
            are fields: FieldValidator<Shape, Value>...
        ) -> Self {
            var newDict = validationsDict
            newDict[path] = { shape in
                var fieldErrors = [Error]()

                fields.forEach { field in
                    do {
                        if let value = shape[keyPath: path] {
                            try field.validate(shape, value)
                        } else {
                            fatalError("Tried to validate a field that does not exist or is nil.")
                        }
                    } catch {
                        fieldErrors.append(error)
                    }
                }

                return fieldErrors
            }

            return .init(newDict)
        }

        func validations<Value>(
            for path: KeyPath<Shape, FieldPartialValue<Value, some Any>?>,
            are fields: FieldValidator<Shape, Value>...
        ) -> Self {
            var newDict = validationsDict
            newDict[path] = { shape in
                var fieldErrors = [Error]()

                fields.forEach { field in
                    do {
                        if let value = shape[keyPath: path] {
                            switch value {
                            case let .complete(complete):
                                try field.validate(shape, complete)
                            case let .partial(_, error):
                                throw FieldError.incomplete(error)
                            }
                        } else {
                            fatalError("Tried to validate a field that does not exist or is nil.")
                        }
                    } catch {
                        fieldErrors.append(error)
                    }
                }

                return fieldErrors
            }

            return .init(newDict)
        }
    #endif
}
