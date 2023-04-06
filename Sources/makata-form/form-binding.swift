// form-binding.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public struct Binding<Source: AnyObject, Value> {
    public var action: (Value) throws -> Value
    public let initialValue: Value?

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

#if swift(<5.8) // issue fixed in swift 5.8!
    public init(
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

public typealias FieldPartialValueKeyPath<Source, Complete, Value> = ReferenceWritableKeyPath<
    Source, FieldPartialValue<Complete, Value>
>
