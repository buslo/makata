// controller-template-page.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import SnapKit
import UIKit

public extension Templates {
    final class Page<Content: UIView>: UIView {
        public private(set) weak var headerView: (UIView & ViewHeader)!
        public private(set) weak var contentView: Content!

        public init(
            headerView: UIView & ViewHeader,
            contentView: Content,
            constraints: (ConstraintMaker) -> Void = { $0.edges.equalToSuperview() }
        ) {
            super.init(frame: .zero)

            if contentView is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }

            addSubview(view: contentView, constraints: constraints)

            addSubview(view: headerView) { make in
                make.top.horizontalEdges.equalToSuperview()
            }

            self.headerView = headerView
            self.contentView = contentView
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }

        override public func layoutSubviews() {
            super.layoutSubviews()

            let size = headerView.systemLayoutSizeFitting(
                .init(width: bounds.width, height: 100),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )

            if let scrollView = contentView as? UIScrollView {
                switch scrollView.contentInsetAdjustmentBehavior {
                case .always, .automatic:
                    scrollView.contentInset = .init(top: size.height, left: 0, bottom: 0, right: 0)
                default:
                    scrollView.contentInset = .zero
                }
            }
        }
    }
}
