// field-partial-value.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public enum FieldPartialValue<Complete, Incomplete> {
    case complete(Complete)
    case partial(Incomplete, Error?)
}

@dynamicMemberLookup
public struct EnsureCompleteFields<Shape> {
    var shape: Shape

    public init(checking shape: Shape) {
        self.shape = shape
    }

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

    public subscript<Value>(dynamicMember member: KeyPath<Shape, Value>) -> Value {
        shape[keyPath: member]
    }
}
