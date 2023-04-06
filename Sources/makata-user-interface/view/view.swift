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
    func renderSubviews<Value>(
        from observer: Observable<Value>.Projection,
        _ lifetime: inout Lifetimeable?,
        @ComponentBuilder _ update: @escaping @MainActor (Value) -> ComponentBuilder.Component
    ) -> Self {
        var lastReferences: [UIView] = []

        lifetime = observer.subscribe { value in
            DispatchQueue.main.async { [unowned self] in
                for reference in lastReferences {
                    reference.removeFromSuperview()
                }

                switch update(value) {
                case let .single(view, maker):
                    addSubview(view.defineConstraints(maker))
                    lastReferences = [view]
                    
                case let .result(views):
                    for (view, maker) in views {
                        addSubview(view.defineConstraints(maker))
                    }
                    
                    lastReferences = views.map { $0.0 }
                }
            }
        }
        
        return self
    }
}

public extension UIView {
    @available(*, deprecated, message: "Call addSubview with defineConstraints as the last method call in its builder chain instead.")
    convenience init(
        containing: some UIView,
        constraints: (ConstraintMaker) -> Void = { $0.edges.equalToSuperview() }
    ) {
        self.init(frame: .zero)

        addSubview(view: containing, constraints: constraints)
    }

    @available(*, deprecated, message: "Call addSubview with defineConstraints as the last method call in its builder chain instead.")
    @discardableResult
    func addSubview(view: some UIView, constraints: (ConstraintMaker) -> Void) -> Self {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.snp.makeConstraints(constraints)

        return self
    }
}
