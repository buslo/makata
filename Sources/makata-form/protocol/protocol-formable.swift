// protocol-formable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Formable: AnyObject {
    associatedtype FormData

    var formHandler: FormHandler<FormData> { get }

    func submitData(form: FormData) async throws
}

public extension Formable {
    func submit() async throws {
        try await formHandler.submit { [unowned self] shape in
            try await submitData(form: shape)
        }
    }
}
