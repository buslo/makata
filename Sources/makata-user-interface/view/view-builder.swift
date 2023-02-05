// view-builder.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

//
//  File.swift
//
//
//  Created by Michael Ong on 2/3/23.
//
import Foundation
import UIKit

@resultBuilder
public enum ComponentBuilder {
    public typealias Component = [UIView]

    public static func buildExpression(_ expression: some UIView) -> Component {
        [expression]
    }

    public static func buildEither(first component: ComponentBuilder.Component) -> ComponentBuilder.Component {
        component
    }

    public static func buildEither(second component: ComponentBuilder.Component) -> ComponentBuilder.Component {
        component
    }

    public static func buildOptional(_ component: ComponentBuilder.Component?) -> ComponentBuilder.Component {
        component ?? []
    }

    public static func buildArray(_ components: [ComponentBuilder.Component]) -> ComponentBuilder.Component {
        components.flatMap { $0 }
    }

    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap { $0 }
    }
}
