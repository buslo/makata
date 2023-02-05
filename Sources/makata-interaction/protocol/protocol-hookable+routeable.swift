// protocol-hookable+routeable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public extension Hookable where Hook: Routeable {
    init(hook: Hook, routeHandler: @MainActor @escaping (Hook.Route) async -> Void) {
        self.init(hook: hook)

        hook.routeHandler(routeHandler)
    }

    init(hook: Hook, routeHandler: @MainActor @escaping (Self, Hook.Route) async -> Void) {
        self.init(hook: hook)

        hook.routeHandler { [unowned self] route in
            await routeHandler(self, route)
        }
    }
}
