// view+uistackview.swift
//
// Code Copyright Buslo Collective
// Created 4/6/23

import Foundation
import makataInteraction
import UIKit

public var DefaultStackSpacing = CGFloat(8)

public extension UIStackView {
    static func horizontal(
        spacing: CGFloat = DefaultStackSpacing,
        alignment: UIStackView.Alignment = .leading,
        distribution: UIStackView.Distribution = .fill,
        @ComponentBuilder components: () -> ComponentBuilder.Component
    ) -> Self {
        let stack = Self(frame: .zero)
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        stack.insetsLayoutMarginsFromSafeArea = false

        stack.setContentHuggingPriority(.required, for: .vertical)

        switch components() {
        case let .single(view, maker):
            stack.addArrangedSubview(view)
            view.snp.makeConstraints(maker)

        case let .result(views):
            for (view, maker) in views {
                stack.addArrangedSubview(view)
                view.snp.makeConstraints(maker)
            }
        }

        return stack
    }

    static func vertical(
        spacing: CGFloat = DefaultStackSpacing,
        alignment: UIStackView.Alignment = .leading,
        distribution: UIStackView.Distribution = .fill,
        @ComponentBuilder components: () -> ComponentBuilder.Component
    ) -> Self {
        let stack = Self(frame: .zero)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        stack.insetsLayoutMarginsFromSafeArea = false

        stack.setContentHuggingPriority(.required, for: .vertical)

        switch components() {
        case let .single(view, maker):
            stack.addArrangedSubview(view)
            view.snp.makeConstraints(maker)

        case let .result(views):
            for (view, maker) in views {
                stack.addArrangedSubview(view)
                view.snp.makeConstraints(maker)
            }
        }

        return stack
    }

    @discardableResult
    func margins(_ insets: UIEdgeInsets, relativeToSafeArea: Bool = false) -> Self {
        isLayoutMarginsRelativeArrangement = true
        insetsLayoutMarginsFromSafeArea = relativeToSafeArea
        layoutMargins = insets

        return self
    }
}

public extension UIStackView {
    static func renderHorizontal<Value>(
        from observable: Observable<Value>.Projection,
        _ lifetime: inout Lifetimeable?,
        spacing: CGFloat = DefaultStackSpacing,
        alignment: UIStackView.Alignment = .leading,
        distribution: UIStackView.Distribution = .fill,
        @ComponentBuilder components: @escaping @MainActor (Value) -> ComponentBuilder.Component
    ) -> Self {
        let stack = Self(frame: .zero)
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        stack.insetsLayoutMarginsFromSafeArea = false

        stack.setContentHuggingPriority(.required, for: .vertical)

        var lastReferences = [UIView]()

        lifetime = observable.subscribe { [unowned stack] value in
            DispatchQueue.main.async {
                lastReferences.forEach {
                    $0.removeFromSuperview()
                }

                switch components(value) {
                case let .single(view, maker):
                    stack.addArrangedSubview(view)
                    view.snp.makeConstraints(maker)

                    lastReferences = [view]
                case let .result(views):
                    for (view, maker) in views {
                        stack.addArrangedSubview(view)
                        view.snp.makeConstraints(maker)
                    }

                    lastReferences = views.map(\.0)
                }
            }
        }

        return stack
    }

    static func renderVertical<Value>(
        from observable: Observable<Value>.Projection,
        _ lifetime: inout Lifetimeable?,
        spacing: CGFloat = DefaultStackSpacing,
        alignment: UIStackView.Alignment = .leading,
        distribution: UIStackView.Distribution = .fill,
        @ComponentBuilder components: @escaping @MainActor (Value) -> ComponentBuilder.Component
    ) -> Self {
        let stack = Self(frame: .zero)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        stack.insetsLayoutMarginsFromSafeArea = false

        stack.setContentHuggingPriority(.required, for: .vertical)

        var lastReferences = [UIView]()

        lifetime = observable.subscribe { [unowned stack] value in
            DispatchQueue.main.async {
                lastReferences.forEach {
                    $0.removeFromSuperview()
                }

                switch components(value) {
                case let .single(view, maker):
                    stack.addArrangedSubview(view)
                    view.snp.makeConstraints(maker)

                    lastReferences = [view]
                case let .result(views):
                    for (view, maker) in views {
                        stack.addArrangedSubview(view)
                        view.snp.makeConstraints(maker)
                    }

                    lastReferences = views.map(\.0)
                }
            }
        }

        return stack
    }
}
