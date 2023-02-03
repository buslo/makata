// protocol-hookable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Hookable: AnyObject {
    associatedtype Hook

    var client: Hook { get }

    init(hook: Hook)
}
