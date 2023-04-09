// form-binding.swift
//
// Code Copyright Buslo Collective
// Created 2/23/23

import Foundation

/**
 A class that provides a generic way of binding data.
 
 The `Binding` struct is generic over a `Source` object and the `Value` that represents a field in
 the `Source` object. The `Source` type is expected to be a `class` while `Value` can be anything.
 
 A `Binding` is a contract between the code consuming the binding by calling `action` and the `source`
 object recording the change triggered by `action`.
 
 A `Binding`'s value can also be transformed and formatted. Transforming a value means converting or
 strengthening its representation by using a more type safe/suitable format, while formatting a value
 just prettifies it on the consuming code's side.
 */
public struct Binding<Source: AnyObject, Value> {
    /// The field Binding consumers would call.
    ///
    /// The method is defined as throwable to allow for transform / format failures to propagate properly.
    public let action: (Value) throws -> Value

    /// The initial value read from the binding's source.
    public let initialValue: Value?

    /**
     Creates a binding.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     */
    public init(
        source: Source,
        to path: ReferenceWritableKeyPath<Source, Value>
    ) {
        action = { [unowned source] value in
            source[keyPath: path] = value

            return value
        }

        initialValue = source[keyPath: path]
    }

    /**
     Creates a binding with its value transformed by a `FieldTransformable`.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     - parameter transform: The transformer responsible of transforming the source type (`Out`) to `Value`.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     
     - remark: _Transform_ is different from _Format_ in the way that format does not record changes into `source` while transform records changes from one type to another in the `source`.
     */
    public init<Out, T: FieldTransformable>(
        source: Source,
        to path: ReferenceWritableKeyPath<Source, Out>,
        transform: T
    ) throws where T.Value == Value, T.Output == Out {
        action = { [unowned source] value in
            source[keyPath: path] = try transform.encode(to: value)

            return value
        }

        initialValue = try transform.decode(from: source[keyPath: path])
    }

    /**
     Creates a binding with its value formatted by a `FieldFormattable`.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     - parameter format: The formatter responsible of formatting `Value`.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     
     - remark: _Transform_ is different from _Format_ in the way that format does not record changes into `source` while transform records changes from one type to another in the `source`.
     */
    public init<F: FieldFormattable>(
        source: Source,
        to path: ReferenceWritableKeyPath<Source, Value>,
        format: F
    ) where F.Input == Value, F.Output == Value {
        action = { [unowned source] value in
            source[keyPath: path] = value

            return format.format(value: value)
        }

        initialValue = source[keyPath: path]
    }

    /**
     Creates a binding with its value transformed by a `FieldTransformable` then formatted by a `FieldFormattable`.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     - parameter transform: The transformer responsible of formatting `Value`.
     - parameter format: The formatter responsible of formatting `Value`.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     
     - remark: _Transform_ is different from _Format_ in the way that format does not record changes into `source` while transform records changes from one type to another in the `source`.
     */
    public init<Out, T: FieldTransformable, F: FieldFormattable>(
        source: Source,
        to path: ReferenceWritableKeyPath<Source, Out>,
        transform: T,
        format: F
    ) throws where T.Value == Value, T.Output == Out, F.Input == Out, F.Output == Value {
        action = { [unowned source] value in
            let rawValue = try transform.encode(to: value)
            source[keyPath: path] = rawValue

            return format.format(value: rawValue)
        }

        initialValue = try transform.decode(from: source[keyPath: path])
    }
}

public extension Binding {
    /**
     Creates a binding with its value transformed by a `FieldTransformable`.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     - parameter transform: The transformer responsible of transforming the source type (`Out`) to `Value`.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     
     The binding also accepts if the value is "`complete`" by handling additional checks before transforming the `Value`.
     
     - remark: _Transform_ is different from _Format_ in the way that format does not record changes into `source` while transform records changes from one type to another in the `source`.
     */
    init<Complete, T: FieldTransformable>(
        source: Source,
        to path: FieldPartialValueKeyPath<Source, Complete, Value>,
        transform: T
    ) where T.Output == Complete, T.Value == Value {
        action = { [unowned source] value in
            do {
                source[keyPath: path] = .complete(try transform.encode(to: value))
            } catch {
                source[keyPath: path] = .partial(value, error)
            }

            return value
        }

        do {
            switch source[keyPath: path] {
            case let .complete(complete):
                initialValue = try transform.decode(from: complete)
            case let .partial(partial, _):
                initialValue = partial
            }
        } catch {
            fatalError("Are you intentionally setting incorrect data?")
        }
    }

    /**
     Creates a binding with its value transformed by a `FieldTransformable` then formatted by a `FieldFormattable`.
     
     - parameter source: The source where to bind.
     - parameter path: The field keypath on where to listen for changes.
     - parameter transform: The transformer responsible of formatting `Value`.
     - parameter format: The formatter responsible of formatting `Value`.
     
     The binding is one-way from consumers calling the `action` method to the `source`.
     
     The binding also accepts if the value is "`complete`" by handling additional checks before transforming the `Value`.
     
     - remark: _Transform_ is different from _Format_ in the way that format does not record changes into `source` while transform records changes from one type to another in the `source`.
     */
    init<Complete, T: FieldTransformable, F: FieldFormattable>(
        source: Source,
        to path: FieldPartialValueKeyPath<Source, Complete, Value>,
        transform: T,
        format: F
    ) where T.Value == Value, T.Output == Complete, F.Input == Complete, F.Output == Value {
        action = { [unowned source] value in
            let partialResult: FieldPartialValue<Complete, Value>

            do {
                partialResult = .complete(try transform.encode(to: value))
            } catch {
                partialResult = .partial(value, error)
            }

            source[keyPath: path] = partialResult

            switch partialResult {
            case let .complete(complete):
                return format.format(value: complete)
            case let .partial(incomplete, _):
                return incomplete
            }
        }

        do {
            switch source[keyPath: path] {
            case let .complete(complete):
                initialValue = try transform.decode(from: complete)
            case let .partial(partial, _):
                initialValue = partial
            }
        } catch {
            fatalError("Are you intentionally setting incorrect data?")
        }
    }
}

public extension Binding {
    #if swift(<5.8)
        init(
            source: Source,
            to path: ReferenceWritableKeyPath<Source, Value?>
        ) {
            action = { [unowned source] value in
                source[keyPath: path] = value

                return value
            }

            initialValue = source[keyPath: path]
        }
    #endif
}

/// A typealias for defining a `ReferenceWritableKeyPath` for a ``FieldPartialValue``.
public typealias FieldPartialValueKeyPath<Source, Complete, Value> = ReferenceWritableKeyPath<
    Source, FieldPartialValue<Complete, Value>
>
