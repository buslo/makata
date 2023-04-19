//
//  SwiftUIView.swift
//  
//
//  Created by Michael Ong on 4/9/23.
//

#if canImport(SwiftUI)

import SwiftUI

public extension SwiftUI.Binding {
    init<FormSource: Formable>(
        form: FormSource,
        field: WritableKeyPath<FormSource.FormData, Value>
    ) {
        self.init {
            return form.formHandler.current[keyPath: field]
        } set: { value in
            form.formHandler.current[keyPath: field] = value
        }
    }

    init<FormSource: Formable, Transform: FieldTransformable>(
        form: FormSource,
        field: WritableKeyPath<FormSource.FormData, Transform.Output>,
        transform: Transform
    ) where Transform.Value == Value {
        self.init {
            do {
                return try transform.decode(from: form.formHandler.current[keyPath: field])
            } catch {
                fatalError("SwiftUI.Binding: Unhandled failure in setting value to text field.\nIf you intend to catch this error, change your target type to be boxed in a `FieldPartialValue`.")
            }
        } set: { value in
            do {
                form.formHandler.current[keyPath: field] = try transform.encode(to: value)
            } catch {
                fatalError("SwiftUI.Binding: Unhandled failure in setting value to text field.\nIf you intend to catch this error, change your target type to be boxed in a `FieldPartialValue`.")
            }
        }
    }

    init<FormSource: Formable, Transform: FieldTransformable, CompleteValue>(
        form: FormSource,
        field: WritableKeyPath<FormSource.FormData, FieldPartialValue<CompleteValue, Value>>,
        transform: Transform
    ) where Transform.Output == CompleteValue, Transform.Value == Value {
        self.init {
            do {
                switch form.formHandler.current[keyPath: field] {
                case .complete(let complete):
                    return try transform.decode(from: complete)
                case .partial(let incomplete, _):
                    return incomplete
                }
            } catch {
                fatalError("Are you intentionally setting incorrect data?")
            }
        } set: { value in
            do {
                form.formHandler.current[keyPath: field] = .complete(try transform.encode(to: value))
            } catch {
                form.formHandler.current[keyPath: field] = .partial(value, error)
            }
        }
    }
}

public extension Formable {
    @available(*, deprecated: 0.0.6, renamed: "formBinding(for:)")
    func binding<Value>(
        for field: WritableKeyPath<FormData, Value>
    ) -> SwiftUI.Binding<Value> {
        formBinding(for: field)
    }

    @available(*, deprecated: 0.0.6, renamed: "formBinding(for:transform:)")
    func binding<Value, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, Transform.Output>,
        transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Value == Value {
        formBinding(for: field, transform: transform)
    }

    @available(*, deprecated: 0.0.6, renamed: "formBinding(for:transform:)")
    func binding<Value, CompleteValue, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, FieldPartialValue<CompleteValue, Value>>,
        transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Output == CompleteValue, Transform.Value == Value {
        formBinding(for: field, transform: transform)
    }
}

public extension Formable {
    func formBinding<Value>(
        for field: WritableKeyPath<FormData, Value>
    ) -> SwiftUI.Binding<Value> {
        .init(form: self, field: field)
    }

    func formBinding<Value, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, Transform.Output>,
        transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Value == Value {
        .init(form: self, field: field, transform: transform)
    }

    func formBinding<Value, CompleteValue, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, FieldPartialValue<CompleteValue, Value>>,
        transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Output == CompleteValue, Transform.Value == Value {
        .init(form: self, field: field, transform: transform)
    }
}

#endif
