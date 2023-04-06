// form-validation.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public struct FormValidation<Shape> {
    public struct Result {
        public static var noErrors: Result { Result(fields: [:]) }

        public let fields: [PartialKeyPath<Shape>: [Error]]
    }

    let validationsDict: [PartialKeyPath<Shape>: (Shape) -> [Error]]

    public init() {
        validationsDict = [:]
    }

    init(_ newDict: [PartialKeyPath<Shape>: (Shape) -> [Error]]) {
        validationsDict = newDict
    }

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

extension FormValidation {
#if swift(<5.8)
    public func validations<Value>(
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

    public func validations<Value>(
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
