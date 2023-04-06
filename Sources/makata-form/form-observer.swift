// form-observer.swift
//
// Code Copyright Buslo Collective
// Created 4/5/23

import Foundation

public struct FormObserver<Shape> {
    let observationDict: [PartialKeyPath<Shape>: (Any) -> Void]

    public init() {
        observationDict = [:]
    }

    init(observationDict: [PartialKeyPath<Shape>: (Any) -> Void]) {
        self.observationDict = observationDict
    }

    public func listenForChanges<Value>(to path: KeyPath<Shape, Value>, _ observer: @escaping (Value) -> Void) -> Self {
        var newDict = observationDict
        newDict.updateValue({ value in
            observer(value as! Value)
        }, forKey: path)

        return .init(observationDict: newDict)
    }
}
