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

    convenience init(
        containing: some UIView,
        constraints: (ConstraintMaker) -> Void = { $0.edges.equalToSuperview() }
    ) {
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
    
    @discardableResult
    func renderSubviews<Value>(
        from observer: Observable<Value>,
        _ lifetime: inout Lifetimeable?,
        @ComponentBuilder _ update: @escaping @MainActor (Value) -> ComponentBuilder.Component
    ) -> Self {
        var lastReferences: [UIView] = []
        
        lifetime = observer.projectedValue.subscribe { [unowned self] value in
            for reference in lastReferences {
                reference.removeFromSuperview()
            }

            switch update(value) {
            case let .single(view, maker):
                addSubview(view: view, constraints: maker)
                lastReferences = [view]
                
            case let .result(views):
                for (view, maker) in views {
                    addSubview(view: view, constraints: maker)
                }
                
                lastReferences = views.map { $0.0 }
            }
        }
        
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
        spacing: CGFloat = 8,
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
        
        lifetime = observable.subscribe { [unowned stack] value in
            switch components(value) {
            case let .single(view, maker):
                stack.addArrangedSubview(view)
                view.snp.makeConstraints(maker)
                
            case let .result(views):
                for (view, maker) in views {
                    stack.addArrangedSubview(view)
                    view.snp.makeConstraints(maker)
                }
            }
        }
        
        return stack
    }
    
    static func renderVertical<Value>(
        from observable: Observable<Value>.Projection,
        _ lifetime: inout Lifetimeable?,
        spacing: CGFloat = 8,
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
        
        lifetime = observable.subscribe { [unowned stack] value in
            switch components(value) {
            case let .single(view, maker):
                stack.addArrangedSubview(view)
                view.snp.makeConstraints(maker)
                
            case let .result(views):
                for (view, maker) in views {
                    stack.addArrangedSubview(view)
                    view.snp.makeConstraints(maker)
                }
            }
        }
        
        return stack
    }
}
