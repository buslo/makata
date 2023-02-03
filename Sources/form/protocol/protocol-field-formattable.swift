// protocol-field-formattable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol FieldFormattable {
    associatedtype Input
    associatedtype Output

    func format(value: Input) -> Output
}
