// protocol-assignable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Assignable: AnyObject {}

public extension Assignable {
    func assign(to target: inout Self?) -> Self {
        target = self

        return self
    }
}
