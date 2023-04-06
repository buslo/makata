// protocol-formable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 Protocol that provides form handling functions to a reference type object.
 */
public protocol Formable: AnyObject {
    /// The form's shape.
    associatedtype FormData

    /// The form handler.
    ///
    /// Implement this field as:
    /// ```swift
    /// let formHandler = FormHandler<FormData>(initialValue: ...)
    /// ```
    ///
    /// You can also delay initialization inside an initializer:
    /// ```swift
    /// let formHandler: FormHandler<FormData>
    ///
    /// init(externalValue) {
    ///     formHandler = FormHandler(initialValue: <use external value here>)
    /// }
    /// ```
    var formHandler: FormHandler<FormData> { get }

    /// Method to implement to perform form submission.
    /// - parameter form: The form data to be used for submission.
    func submitData(form: FormData) async throws
}

public extension Formable {
    /// Method to submit the form.
    /// - remark: If there are validation errors in your form, `submitData` will not be called.
    func submit() async throws {
        try await formHandler.submit { [unowned self] shape in
            try await submitData(form: shape)
        }
    }
}
