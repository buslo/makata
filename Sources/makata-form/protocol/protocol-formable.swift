// protocol-formable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 Protocol that provides form handling functions to a reference type object.
 
 Use this protocol as follows:
 
 For UIKit:
 ```swift
 class YourViewController: UIViewController, Formable {
    let formHandler = FormHandler<YourForm>(initialValue: YourForm(...))
        .setValidationHandler(FormValidation()
            .validations(for: \.yourField, are: .validator, .validator2)
        )

    var yourFieldField: Lifetimeable!
 
    override func viewDidLoad() {
        super.viewDidLoad()
 
        UIButton(configuration: ..., primaryAction: UIAction { _ in Task { try await submit() } })
 
        UITextField()
            .textChanges(Binding(source: formHandler, to: \.yourField), lifetime: &yourFieldField)
    }
 
    func submitData(_ form: YourForm) async throws {
        try await api.submitForSubmission(form)
    }
 }
 ```
 
 For SwiftUI:
 ```swift
 struct FormScreen: Formable, View {
     struct FormData {
         var name: String
     }

     let formHandler = FormHandler(initial: FormData(name: ""))
         .setValidationHandler(FormValidation()
             .validations(for: \.yourField, are: .validator, .validator2)
         )

     var body: some View {
         SwiftUI.Form {
             TextField("Name", text: formBinding(for: \.name))
             Button("Submit", action: defineSubmit(onSuccess: {
                // What happens on success
             }, onFailure: { error in
                // What happens on failure
             }))
         }
     }

     func submitData(form: FormData) async throws {
         try await api.submitForSubmission(form)
     }
 }
 ```
 
 */
public protocol Formable {
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

public extension Formable where Self: AnyObject {
    /// Method to submit the form.
    /// - remark: If there are validation errors in your form, `submitData` will not be called.
    func submit() async throws {
        try await formHandler.submit { [unowned self] shape in
            try await submitData(form: shape)
        }
    }
}

public extension Formable {
    func defineSubmit(
        onInvoked: @escaping () -> Void,
        onSuccess: (() -> Void)? = nil,
        onFailure: @escaping (Error) -> Void
    ) -> () -> Void {
        return {
            onInvoked()
            
            Task {
                do {
                    try await formHandler.submit { shape in
                        try await submitData(form: shape)
                    }
                    
                    if let onSuccess {
                        await MainActor.run {
                            onSuccess()
                        }
                    }
                } catch {
                    await MainActor.run {
                        onFailure(error)
                    }
                }
            }
        }
    }
    
    func defineSubmit(onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) -> () -> Void {
        return {
            Task {
                do {
                    try await formHandler.submit { shape in
                        try await submitData(form: shape)
                    }
                    
                    await MainActor.run {
                        onSuccess()
                    }
                } catch {
                    await MainActor.run {
                        onFailure(error)
                    }
                }
            }
        }
    }
}
