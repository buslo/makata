// protocol-button-loadable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol ButtonLoadable: AnyObject {
    var isLoading: Bool { get set }
}
