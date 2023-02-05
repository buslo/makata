// protocol-observable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

@propertyWrapper
public final class Observable<Value> {
    public var wrappedValue: Value {
        didSet {
            subscriptions.forEach { item in
                item.action(wrappedValue)
            }
        }
    }

    public var projectedValue: Projection {
        .init(observable: self)
    }

    var subscriptions: [Subscription] = []

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

public extension Observable {
    class Subscription: Lifetimeable {
        public static func equal(source: Subscription) -> (Subscription) -> Bool {
            { check in check.id == source.id }
        }

        let id: Int
        let source: String
        let action: (Value) -> Void

        weak var observable: Observable<Value>!

        init(id: Int, source: String, action: @escaping (Value) -> Void) {
            self.id = id
            self.source = source
            self.action = action
        }

        deinit {
            cancel()
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public func cancel() {
            observable.subscriptions.removeAll(where: Subscription.equal(source: self))
        }
    }

    struct Projection {
        weak var observable: Observable<Value>!

        public func subscribe(
            source: @autoclosure () -> String = "[\(#file)]@\(#line) > \(#filePath)",
            action: @escaping (Value) -> Void
        ) -> Lifetimeable {
            let newSubscription = Subscription(id: observable.subscriptions.count, source: source(), action: action)
            newSubscription.observable = observable

            observable.subscriptions.append(newSubscription)

            return newSubscription
        }

        public func bind(
            source: @autoclosure () -> String = "[\(#file)]@\(#line) > \(#filePath)",
            to loadable: some Loadable
        ) -> Lifetimeable {
            subscribe(source: source()) { [weak loadable] _ in
                guard let loadable else {
                    return
                }

                Task {
                    await loadable.invalidate()
                }
            }
        }
    }
}
