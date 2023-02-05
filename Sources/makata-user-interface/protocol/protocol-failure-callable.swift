// protocol-failure-callable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol FailureCallable: AnyObject {
    func showFailure(_ error: Error)
}
