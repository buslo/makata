// protocol-stateable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Stateable: AnyObject {
    associatedtype State

    var stateHandler: StateHandler<State> { get }
}

public extension Stateable {
    func updateState(to state: State) async {
        await stateHandler.provider(state)
    }
}

public class StateHandler<State> {
    public typealias Provider = @MainActor (State) async -> Void

    var provider: Provider = { _ in }

    public var current: State

    public init(initial: State) {
        current = initial
    }

    public func callAsFunction(_ callback: @escaping Provider) {
        provider = callback

        Task {
            await callback(current)
        }
    }
}
