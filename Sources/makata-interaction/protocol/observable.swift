// protocol-observable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import Combine

extension AnyCancellable: Lifetimeable {
    
}

extension Published.Publisher {
    public func subscribe(action: @escaping (Value) -> Void) -> Lifetimeable {
        sink { value in
            action(value)
        }
    }

    public func bind(to loadable: some Loadable) -> Lifetimeable {
        subscribe { [weak loadable] _ in
            guard let loadable else {
                return
            }

            Task {
                await loadable.invalidate()
            }
        }
    }
}
