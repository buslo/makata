// view-builder.swift
//
// Code Copyright Buslo Collective
// Created 3/12/23

import Foundation
import SnapKit
import UIKit

@resultBuilder
public enum ComponentBuilder {
    public enum Component {
        case single(UIView, (ConstraintMaker) -> Void)
        case result([(UIView, (ConstraintMaker) -> Void)])
    }

    public static func buildExpression(_ expression: some UIView) -> Component {
        .single(expression) { _ in }
    }

    public static func buildExpression(_ expression: ConstructedViewWithConstraints<some UIView>) -> Component {
        .single(expression.view, expression.constraint)
    }

    public static func buildExpression(_ expression: [UIView]) -> Component {
        .result(expression.map { ($0, { _ in }) })
    }

    public static func buildEither(first component: ComponentBuilder.Component) -> ComponentBuilder.Component {
        component
    }

    public static func buildEither(second component: ComponentBuilder.Component) -> ComponentBuilder.Component {
        component
    }

    public static func buildOptional(_ component: ComponentBuilder.Component?) -> ComponentBuilder.Component {
        component ?? .result([])
    }

    public static func buildArray(_ components: [ComponentBuilder.Component]) -> ComponentBuilder.Component {
        var items = [(UIView, (ConstraintMaker) -> Void)]()

        for component in components {
            switch component {
            case let .single(view, maker):
                items.append((view, maker))
            case let .result(existing):
                items.append(contentsOf: existing)
            }
        }

        return .result(items)
    }

    public static func buildBlock(_ components: Component...) -> Component {
        var items = [(UIView, (ConstraintMaker) -> Void)]()

        for component in components {
            switch component {
            case let .single(view, maker):
                items.append((view, maker))
            case let .result(existing):
                items.append(contentsOf: existing)
            }
        }

        return .result(items)
    }
}
