// view+uitextfield.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import makataForm
import makataInteraction
import UIKit

public extension UITextField {
    func textChanges(_ action: Binding<some AnyObject, String>, maxLength: Int = .max) -> Lifetimeable {
        text = action.initialValue

        return TextChangesProxy(source: self, action: action.action, maxLength: maxLength)
    }

    @discardableResult
    func textChanges(_ action: Binding<some AnyObject, String>, maxLength: Int = .max, lifetime: inout Lifetimeable?) -> Self {
        lifetime = textChanges(action, maxLength: maxLength)

        return self
    }
}

extension UITextField {
    private class TextChangesProxy: Lifetimeable {
        let identifier = UIAction.Identifier("textfield.changes")

        weak var source: UITextField!

        init(source: UITextField, action: @escaping (String) throws -> String, maxLength: Int) {
            self.source = source

            source.addAction(UIAction(identifier: identifier) { [unowned source] _ in
                do {
                    source.text = try action(String((source.text ?? "").prefix(maxLength)))
                } catch {
                    print("TextChangesProxy: Unhandled failure in setting value to text field.")
                    print("If you intend to catch this error, change your target type to be boxed in a `PartialValue`.")
                }
            }, for: .allEditingEvents)
        }

        deinit {
            cancel()
        }

        func cancel() {
            source?.removeAction(identifiedBy: identifier, for: .allEditingEvents)
        }
    }
}
