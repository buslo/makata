// protocol-attributable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Attributable: AnyObject {}

public extension Attributable {
    func attribute<Value>(on: ReferenceWritableKeyPath<Self, Value>, _ value: Value) -> Self {
        self[keyPath: on] = value

        return self
    }
}
