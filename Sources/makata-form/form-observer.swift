// form-observer.swift
//
// Code Copyright Buslo Collective
// Created 4/5/23

import Foundation

/**
 Builder object to define form side effect listeners.
 
 The `FormValidation` class is generic over a `Shape` type, which represents the shape of the form data that it will listen for side effects. The Shape type is expected to be a `struct`, and each property of the `Shape` type represents a field that can be listened to.
 */
public struct FormObserver<Shape> {
    let observationDict: [PartialKeyPath<Shape>: (Any) -> Void]

    /**
     Create a new validation builder.
     */
    public init() {
        observationDict = [:]
    }

    init(observationDict: [PartialKeyPath<Shape>: (Any) -> Void]) {
        self.observationDict = observationDict
    }

    /**
     Define a side effect listener for a field.
     
     - parameter path: The field path to listen.
     - parameter observer: The function that will be ran when the field's value changes.
     
     Do note that calling this method a second time will override previously defined listeners.
     */
    public func listenForChanges<Value>(to path: KeyPath<Shape, Value>, _ observer: @escaping (Value) -> Void) -> Self {
        var newDict = observationDict
        newDict.updateValue({ value in
            observer(value as! Value)
        }, forKey: path)

        return .init(observationDict: newDict)
    }
}
