// field-partial-value.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/// A value that represents either a field is `complete` or `incomplete`.
///
/// A `complete` value means a ``FieldTransformable`` was able to ``FieldTransformable/encode(to:)``
/// the value.
///
/// An `incomplete` value means a ``FieldTransformable`` threw an error while performing ``FieldTransformable/encode(to:)``.
public enum FieldPartialValue<Complete, Incomplete> {
    case complete(Complete)
    case partial(Incomplete, Error?)
}

/// A struct that ensures all the fields in `Shape` is complete.
///
/// The `EnsureCompleteFields` struct is generic over the `Shape` type that represents the
/// object to check any ``FieldPartialValue`` fields are `complete`.
@dynamicMemberLookup
public struct EnsureCompleteFields<Shape> {
    var shape: Shape

    /// Creates the object.
    public init(checking shape: Shape) {
        self.shape = shape
    }

    ///
    /// Allows to check if a value is `complete` or not.
    ///
    /// - parameter member: The field path to check.
    /// - returns: The value if the field is `complete` or throws if the field is `incomplete`.
    ///
    /// If the value is `incomplete`, this subscript will return an error.
    ///
    /// To use this subscript do:
    ///
    /// ```swift
    /// var formData = EnsureCompleteFields(YourFormData(...))
    /// var field = try formData.partialField
    /// ```
    ///
    public subscript<Value>(dynamicMember member: KeyPath<Shape, FieldPartialValue<Value, some Any>>) -> Value {
        get throws {
            switch shape[keyPath: member] {
            case let .partial(_, error):
                if let error {
                    throw error
                } else {
                    fatalError()
                }
            case let .complete(value):
                return value
            }
        }
    }

    ///
    /// Passthrough for non-``FieldPartialValue`` fields.
    ///
    /// - parameter member: The field path to check.
    ///
    public subscript<Value>(dynamicMember member: KeyPath<Shape, Value>) -> Value {
        shape[keyPath: member]
    }
}
