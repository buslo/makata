// protocol-field-transformable.swift
//
// Code Copyright Buslo Collective
// Created 2/23/23

import Foundation

public protocol FieldTransformable {
    associatedtype Value
    associatedtype Output

    func encode(to value: Value) throws -> Output
    func decode(from value: Output) throws -> Value
}
