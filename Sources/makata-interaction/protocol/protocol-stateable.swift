// protocol-stateable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import SwiftUI
import Combine

/**
 Protocol to allow a reference-type object to have state handling.
 
 This protocol has an associated type of `State` that can be any object that represents the shape of the state this protocol will manage.
 
 Use this protocol as follows:
 
 For UIKit:
 ```swift
 class YourHandler: Stateable {
    struct State {
        let name: String
    }
 
    let stateHandler = StateHandler<State>(initial: .init(name: "Hello"))
 
    func updateName(to newName: String) async {
        await updateState(to: .init(name: newName))
    }
 }
 
 class YourController: UIViewController {
    let handler = YourHandler()
 
    var nameLabel: UILabel!
 
    override func viewDidLoad() {
        super.viewDidLoad()
 
        // initialize view for nameLabel
 
        handler.stateHandler { [unowned self] current in
            nameLabel.text = current.name
        }
    }
 }
 ```
 
 For SwiftUI:
 ```swift
 struct YourSwiftUIScreen: View, Stateable {
    struct State {
        let name: String
    }

    @ObservedObject var stateHandler = StateHandler<State>(initial: .init(name: "Hello"))

    var body: some View {
        VStack {
            Text(stateHandler.current.name)
        }
    }
 }
 */
public protocol Stateable {
    /// The object that represents the state this protocol will manage.
    associatedtype State

    /**
     The variable that handles state management.
     */
    var stateHandler: StateHandler<State> { get }
}

public extension Stateable {
    /**
     Method to update the current state.
     
     - Parameter state: The new state to apply.
     */
    func updateState(to state: State) async {
        await stateHandler.provider(state)
        
        stateHandler.current = state
    }
}

/**
 The object that handles state management.
 
 This object is generic over a `State` type which determines the shape of the state this object will manage.
 
 - Remark: Do not define this object in your classes directly. Instead, conform to ``Stateable``.
 */
public final class StateHandler<State>: ObservableObject, Sendable {
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
