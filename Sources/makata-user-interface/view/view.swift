// view.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import makataInteraction
import SnapKit
import UIKit

extension UIView: Assignable, Attributable, Withable {}

public extension UIView {
    static func stackFiller() -> UIView {
        let view = UIView()
        view.setContentHuggingPriority(.init(rawValue: 0), for: .horizontal)
        view.setContentHuggingPriority(.init(rawValue: 0), for: .vertical)

        return view
    }

    static func stackBlock(height: CGFloat = 8) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true

        return view
    }

    convenience init(containing: some UIView, constraints: (ConstraintMaker) -> Void) {
        self.init(frame: .zero)

        addSubview(view: containing, constraints: constraints)
    }

    @discardableResult
    func autoFocus() -> Self {
        becomeFirstResponder()
        return self
    }

    @discardableResult
    func sized(_ size: CGSize, rounded: Bool = false) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = rounded ? size.height / 2 : 0
        layer.masksToBounds = true

        snp.makeConstraints { make in
            if !size.width.isNaN {
                make.width
                    .equalTo(size.width)
                    .priority(.required)
            }

            if !size.height.isNaN {
                make.height
                    .equalTo(size.height)
                    .priority(.required)
            }
        }

        return self
    }

    @discardableResult
    func backgroundColor(_ color: UIColor) -> Self {
        backgroundColor = color

        return self
    }

    @discardableResult
    func hidden() -> Self {
        isHidden = true

        return self
    }

    @discardableResult
    func visible() -> Self {
        isHidden = false

        return self
    }

    @discardableResult
    func addSubview(view: some UIView, constraints: (ConstraintMaker) -> Void) -> Self {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.snp.makeConstraints(constraints)

        return self
    }
}

public extension UIStackView {
    static func horizontal(
        spacing: CGFloat = 8,
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

        components().forEach(stack.addArrangedSubview)

        return stack
    }

    static func vertical(
        spacing: CGFloat = 8,
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

        components().forEach(stack.addArrangedSubview)

        return stack
    }

    convenience init(
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .leading,
        distribution: UIStackView.Distribution = .fill,
        @ComponentBuilder components: () -> ComponentBuilder.Component
    ) {
        self.init(frame: .zero)

        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
        self.distribution = distribution
        insetsLayoutMarginsFromSafeArea = false

        components().forEach(addArrangedSubview)
    }

    @discardableResult
    func margins(_ insets: UIEdgeInsets, relativeToSafeArea: Bool = false) -> Self {
        isLayoutMarginsRelativeArrangement = true
        insetsLayoutMarginsFromSafeArea = relativeToSafeArea
        layoutMargins = insets

        return self
    }
}