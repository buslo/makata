// protocol-routeable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Routeable: AnyObject {
    associatedtype Route

    var routeHandler: RouteCallback<Route> { get set }
}

public extension Routeable {
    func updateRoute(to route: Route) async {
        await routeHandler.provider(route)
    }
}

public class RouteCallback<Route> {
    public typealias Provider = @MainActor (Route) async -> Void

    var provider: Provider = { _ in }

    public init() {}

    public func callAsFunction(_ callback: @escaping Provider) {
        provider = callback
    }
}
