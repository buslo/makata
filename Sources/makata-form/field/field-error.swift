// field-error.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public enum FieldError: LocalizedError {
    case required
    case wrongFormat
    case invalid(String)
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
