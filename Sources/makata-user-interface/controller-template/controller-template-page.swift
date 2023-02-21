// controller-template-page.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import SnapKit
import UIKit

public extension Templates {
    final class Page: UIView, HasHeader {
        public private(set) weak var headerView: (UIView & ViewHeader)?
        public private(set) weak var contentView: UIView!

        public lazy var contentViewLayoutGuide: UILayoutGuide = {
            let layoutGuide = UILayoutGuide()
            addLayoutGuide(layoutGuide)

            layoutGuide.snp.makeConstraints { make in
                make.top
                    .equalTo(headerView!.snp.bottom)

                make.horizontalEdges
                    .bottom
                    .equalToSuperview()
            }

            return layoutGuide
        }()

        public init(
            header: __owned UIView & ViewHeader,
            content: __owned UIView,
            contentConstraints: (Page, ConstraintMaker) -> Void = { $1.edges.equalToSuperview() }
        ) {
            super.init(frame: .zero)

            if content is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }

            headerView = header
            contentView = content

            addSubview(view: content) { make in
                contentConstraints(self, make)
            }

            addSubview(view: header) { make in
                make.top.horizontalEdges.equalToSuperview()
            }
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }

        override public func layoutSubviews() {
            super.layoutSubviews()

            let size = headerView!.systemLayoutSizeFitting(
                .init(width: bounds.width, height: 100),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )

            if let scrollView = contentView as? UIScrollView {
                switch scrollView.contentInsetAdjustmentBehavior {
                case .always, .automatic:
                    scrollView.contentInset = .init(top: size.height - safeAreaInsets.top, left: 0, bottom: 0, right: 0)
                default:
                    scrollView.contentInset = .zero
                }
            }
        }
    }
}
