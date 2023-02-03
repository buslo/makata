// protocol-withable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Withable {}

public extension Withable {
    func with(_ closure: (Self) -> Void) -> Self {
        closure(self)

        return self
    }

    func with<Value>(path: KeyPath<Self, Value>, _ closure: (Value) -> Void) -> Self {
        closure(self[keyPath: path])

        return self
    }
}
