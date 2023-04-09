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
        self.init { [unowned form] in
            return form.formHandler.current[keyPath: field]
        } set: { [unowned form] value in
            form.formHandler.current[keyPath: field] = value
        }
    }

    init<FormSource: Formable, Transform: FieldTransformable>(
        form: FormSource,
        field: WritableKeyPath<FormSource.FormData, Transform.Output>,
        transform: Transform
    ) where Transform.Value == Value {
        self.init { [unowned form] in
            do {
                return try transform.decode(from: form.formHandler.current[keyPath: field])
            } catch {
                fatalError("SwiftUI.Binding: Unhandled failure in setting value to text field.\nIf you intend to catch this error, change your target type to be boxed in a `FieldPartialValue`.")
            }
        } set: { [unowned form] value in
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
    func binding<Value>(
        for field: WritableKeyPath<FormData, Value>
    ) -> SwiftUI.Binding<Value> {
        .init(form: self, field: field)
    }

    func binding<Value, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, Transform.Output>,
        transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Value == Value {
        .init(form: self, field: field, transform: transform)
    }

    func binding<Value, CompleteValue, Transform: FieldTransformable>(
        for field: WritableKeyPath<FormData, FieldPartialValue<CompleteValue, Value>>,
        transform transform: Transform
    ) -> SwiftUI.Binding<Value> where Transform.Output == CompleteValue, Transform.Value == Value {
        .init(form: self, field: field, transform: transform)
    }
}

struct TestForm {
    var date: FieldPartialValue<Date, String>
}

class TestFormClient: Formable {
    var formHandler: FormHandler<TestForm> = .init(initial: .init(date: .partial("", nil)))
    
    func submitData(form: TestForm) async throws {

    }
}

struct DateTransformer: FieldTransformable {
    func decode(from value: Date) throws -> String {
        fatalError()
    }
    
    func encode(to value: String) throws -> Date {
        fatalError()
    }
}

func testView() -> some View {
    let client = TestFormClient()
    return TextField("Enter Text here", text: client.binding(for: \.date, transform: DateTransformer()))
}

#endif
