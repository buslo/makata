// form-handler.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import SwiftUI
import Combine

/**
 A class that provides a generic way of handling form data.
 
 The `FormHandler` class is generic over a `Shape` type, which represents the shape of the form data that it handles.
 The Shape type is expected to be a `struct`, and each property of the `Shape` type represents a field in the form.
 */
@dynamicMemberLookup
public class FormHandler<Shape>: ObservableObject {
    /**
     Contains definitions when form validation failed.
     */
    public enum Errors: Error {
        case invalid(FormValidation<Shape>.Result)
    }

    /**
     Contains information about the current state of the form.
     */
    public struct State {
        /// `true` if the current form is valid.
        public let isValid: Bool

        /// `true` if the `submit` method is called.
        public let isSubmitInvoked: Bool

        /// `true` if actions inside the `submit` action threw an error.
        public var isSubmitFailed: Bool {
            submitErrors != nil
        }

        /// Contains information on why `submit` failed.
        public let submitErrors: Error?

        /// Validaiton result.
        public let validationResult: FormValidation<Shape>.Result
    }

    public typealias UpdatesHandler = (Shape, State) async -> Void

    /// The current recorded values of the form.
    @Published public internal(set) var current: Shape

    @Published public internal(set) var currentState: State?

    var submitInvoked: Bool
    var submitErrors: Error?

    var updateHandler: UpdatesHandler = { _, _ async in }

    var validations: FormValidation<Shape>?

    var observations: FormObserver<Shape>?

    /**
     Creates a new `FormHandler` instance.
     
     - parameter initial: The initial state of the form.
     - parameter submitInvoked: Override if the form should be created with a submitted state.
     */
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

    @MainActor @discardableResult
    func pushUpdates() async -> FormValidation<Shape>.Result {
        let result = validations?.validate(current) ?? .noErrors
        let newState = State(
            isValid: result.fields.isEmpty,
            isSubmitInvoked: submitInvoked,
            submitErrors: submitErrors,
            validationResult: result
        )

        currentState = newState

        await updateHandler(current, newState)

        return result
    }
}

public extension FormHandler {
    /**
     Handler to hook form updates onto.
     
     - parameter callback: The handler accepting form state changes.
     
     */
    @discardableResult
    func callAsFunction(_ callback: @escaping UpdatesHandler) -> Self {
        updateHandler = callback

        Task { @MainActor () in await pushUpdates() }

        return self
    }

    /**
     Handler to add validations to the form.
     
     - parameter handler: A generic `FormValidation` struct that defines the validations for the form.
     
     Call this method after form initialization:
     
     ```swift
     let form = FormHandler(initial: .init(...))
     form.setValidationHandler(FormValidation())
     ```
     
     Even though this method can chain other `FormHandler` methods, any succeeding calls to this method will override
     the currently stored validations.
     */
    @discardableResult
    func setValidationHandler(_ handler: FormValidation<Shape>?) -> Self {
        validations = handler

        Task { @MainActor () in await pushUpdates() }

        return self
    }

    /**
     Handler to listen side-effects when a form field changes..
     
     - parameter handler: A generic `FormObserver` struct that defines which fields would send side-effects.
     
     Call this method after form initialization:
     
     ```swift
     let form = FormHandler(initial: .init(...))
     form.setObserverHandler(FormObserver())
     ```
     
     Even though this method can chain other `FormHandler` methods, any succeeding calls to this method will override
     the currently stored side-effect listeners.
     */
    @discardableResult
    func setObserverHandler(_ handler: FormObserver<Shape>?) -> Self {
        observations = handler

        return self
    }
}

public extension FormHandler {
    /**
     Allows direct read-write access to the form's current recorded state.
     
     To use this, just do:
     
     ```swift
     let formHandler = FormHandler()
     formHandler.field = "Something"
     ```
     
     When accessing or writing form data, use this subscript instead of calling `handler.current.field`. Accessing through the subscript guarantees form events like side-effects and validations would run predictably.
     
     */
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
