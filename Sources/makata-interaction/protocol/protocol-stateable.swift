// protocol-stateable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import SwiftUI
import Combine

public protocol Stateable: AnyObject {
    associatedtype State

    var stateHandler: StateHandler<State> { get }
}

public extension Stateable {
    func updateState(to state: State) async {
        stateHandler.current = state

        await stateHandler.provider(state)
    }
}

public class StateHandler<State>: ObservableObject {
    public typealias Provider = @MainActor (State) async -> Void

    var provider: Provider = { _ in }

    @Published public internal(set) var current: State

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

class Client: Stateable, ObservableObject {
    struct State {
        let name: String
    }

    @StateObject var stateHandler = StateHandler<State>(initial: State(name: ""))
}

struct Screen: View {
    @ObservedObject var client: Client

    var body: some View {
        Text(client.stateHandler.current.name)
    }
}
