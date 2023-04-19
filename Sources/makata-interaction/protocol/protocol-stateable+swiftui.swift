//
//  File.swift
//  
//
//  Created by Michael Ong on 4/19/23.
//

import Combine
import Foundation
import SwiftUI

public extension Stateable {
    func mapToState<Value>(_ path: KeyPath<State, Value>) -> AnyPublisher<Value, Never> {
        stateHandler.$current.map(path).eraseToAnyPublisher()
    }
    
    func mapToState<Value: Equatable>(_ path: KeyPath<State, Value>) -> AnyPublisher<Value, Never> {
        stateHandler.$current.map(path).removeDuplicates().eraseToAnyPublisher()
    }
}

public extension View {
    func onEffect<Value>(from state: AnyPublisher<Value, Never>, changes receive: Binding<Value>) -> some View {
        onReceive(state) { value in
            receive.wrappedValue = value
        }
    }
}
