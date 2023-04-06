// protocol-field-transformable.swift
//
// Code Copyright Buslo Collective
// Created 2/23/23

import Foundation

/**
 Protocol that defines a field can be transformed.
 
 Transforming a field is a two-way operation that will be recorded to the binding's source. See `Binding` for more information.
 */
public protocol FieldTransformable {
    associatedtype Value
    associatedtype Output

    /**
     Encode data from the consumer to the expected source type.
     */
    func encode(to value: Value) throws -> Output
    /**
     Decode data from the source type to the consuming type.
     */
    func decode(from value: Output) throws -> Value
}
