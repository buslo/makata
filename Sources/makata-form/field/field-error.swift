// field-error.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

/**
 Represents errors that a form's validation can throw.
 */
public enum FieldError: LocalizedError {
    /// Field is required.
    case required
    /// Field is in a wrong format.
    case wrongFormat
    /// Field's validation has failed.
    case invalid(String)
    /// If the Field is a ``FieldPartialValue``, represents the field is still incomplete.
    case incomplete(Error?)

    public var errorDescription: String? {
        switch self {
        case .required:
            return "is required"
        case .wrongFormat:
            return "is in a wrong format"
        case let .incomplete(error):
            if let error {
                return "is incomplete, \(error.localizedDescription)"
            } else {
                return "is incomplete"
            }
        case let .invalid(string):
            return string
        }
    }
}
