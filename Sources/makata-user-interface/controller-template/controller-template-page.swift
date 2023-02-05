// controller-template-page.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import SnapKit
import UIKit

public extension Templates {
    final class Page: UIView {
        public private(set) weak var headerView: (UIView & ViewHeader)!
        public private(set) weak var contentView: UIView!

        public init(
            header: UIView & ViewHeader,
            content: UIView,
            contentConstraints: (Page, ConstraintMaker) -> Void = { $1.edges.equalToSuperview() }
        ) {
            super.init(frame: .zero)

            if content is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }

            addSubview(view: content) { make in
                contentConstraints(self, make)
            }

            addSubview(view: header) { make in
                make.top.horizontalEdges.equalToSuperview()
            }

            self.headerView = header
            self.contentView = content
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
