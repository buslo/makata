// form.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import makataInteraction

@dynamicMemberLookup
public class FormHandler<Shape> {
    public enum Errors: Error {
        case invalid(FormValidation<Shape>.Result)
    }

    public struct State {
        public let isValid: Bool
        public let isSubmitInvoked: Bool

        public var isSubmitFailed: Bool {
            submitErrors != nil
        }
        
        public let submitErrors: Error?

        public let validationResult: FormValidation<Shape>.Result
    }

    public typealias UpdatesHandler = (Shape, State) async -> Void

    public var current: Shape

    var submitInvoked: Bool
    var submitErrors: Error?
    
    var updateHandler: UpdatesHandler = { _, _ async in }

    var validations: FormValidation<Shape>?
    
    var observations: FormObserver<Shape>?

    public init(initial: Shape, submitInvoked: Bool = false) {
        self.current = initial
        self.submitInvoked = submitInvoked
    }

    func submit(_ callback: @escaping (Shape) async throws -> Void) async throws {
        submitInvoked = true

        let errors = await pushUpdates()

        if !errors.fields.isEmpty {
            throw Errors.invalid(errors)
        }

        do {
            try await callback(current)
            submitErrors = nil
        } catch {
            submitErrors = error
            await pushUpdates()
            
            throw error
        }
    }

    @discardableResult
    func pushUpdates() async -> FormValidation<Shape>.Result {
        let result = validations?.validate(current) ?? .noErrors
        await updateHandler(
            current,
            .init(
                isValid: result.fields.isEmpty,
                isSubmitInvoked: submitInvoked,
                submitErrors: submitErrors,
                validationResult: result
            )
        )
        
        return result
    }
}

public extension FormHandler {
    @discardableResult
    func callAsFunction(_ callback: @escaping UpdatesHandler) -> Self {
        updateHandler = callback

        Task { @MainActor () in await pushUpdates() }

        return self
    }

    @discardableResult
    func setValidationHandler(_ handler: FormValidation<Shape>?) -> Self {
        validations = handler

        Task { @MainActor () in await pushUpdates() }

        return self
    }
    
    @discardableResult
    func setObserverHandler(_ handler: FormObserver<Shape>?) -> Self {
        observations = handler
        
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
            
            if let observations, let action = observations.observationDict[member] {
                action(newValue)
            }
            
            Task { @MainActor () in await pushUpdates() }
        }
    }
}
