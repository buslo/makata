// form.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

@dynamicMemberLookup
public class FormHandler<Shape> {
    public enum Errors: Error {
        case invalid(FormValidation<Shape>.Result)
    }

    public struct State {
        public let isValid: Bool
        public let validationResult: FormValidation<Shape>.Result
    }

    public typealias UpdatesHandler = (Shape, State) async -> Void

    public var current: Shape

    var updateHandler: UpdatesHandler = { _, _ async in }

    var validations: FormValidation<Shape>?

    public init(initial: Shape) {
        self.current = initial
    }

    func submit(_ callback: @escaping (Shape) async throws -> Void) async throws {
        let errors = validations?.validate(current) ?? .noErrors

        if !errors.fields.isEmpty {
            throw Errors.invalid(errors)
        }

        try await callback(current)
    }

    func pushUpdates() {
        Task {
            let result = validations?.validate(current) ?? .noErrors
            await updateHandler(current, .init(isValid: result.fields.isEmpty, validationResult: result))
        }
    }
}

public extension FormHandler {
    @discardableResult
    func callAsFunction(_ callback: @escaping UpdatesHandler) -> Self {
        updateHandler = callback

        pushUpdates()

        return self
    }

    @discardableResult
    func setValidationHandler(_ handler: FormValidation<Shape>?) -> Self {
        validations = handler

        pushUpdates()

        return self
    }
}

public extension FormHandler {
    subscript<Value>(dynamicMember member: WritableKeyPath<Shape, Value>) -> Value {
        get {
            current[keyPath: member]
        }
        set {
            current[keyPath: member] = newValue
            pushUpdates()
        }
    }
}
