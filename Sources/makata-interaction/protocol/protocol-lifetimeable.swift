// protocol-lifetimeable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Lifetimeable: AnyObject {
    func cancel()
}
