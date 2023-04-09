// protocol-field-formattable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 Protocol that defines a field can be formatted.
 
 Formatting a field is a one-way operation that will not be recorded to the binding's source. See `Binding` for more information.
 */
public protocol FieldFormattable {
    associatedtype Input
    associatedtype Output

    /**
     Format data from one type to another.
     */
    func format(value: Input) -> Output
}
