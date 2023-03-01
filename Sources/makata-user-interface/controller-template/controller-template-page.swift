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
        public private(set) weak var footerView: UIView?
        
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
            footer: __owned UIView = UIView(),
            content: __owned UIView,
            contentConstraints: (Page, ConstraintMaker) -> Void = { $1.edges.equalToSuperview() }
        ) {
            super.init(frame: .zero)

            if content is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }

            headerView = header
            footerView = footer
            contentView = content

            addSubview(content)

            header.snp.contentHuggingVerticalPriority = UILayoutPriority.required.rawValue
            footer.snp.contentHuggingVerticalPriority = UILayoutPriority.required.rawValue

            addSubview(view: header) { make in
                make.top
                    .horizontalEdges
                    .equalToSuperview()
            }
            
            addSubview(view: footer) { make in
                make.bottom
                    .horizontalEdges
                    .equalToSuperview()
            }
            
            content.snp.makeConstraints { make in
                contentConstraints(self, make)
            }
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }
        
        public override func layoutSubviews() {
            if let scrollView = contentView as? UIScrollView {
                var topOffset: CGFloat = 0
                var bottomOffset: CGFloat = 0
                
                if let header = headerView {
                    let size = header.systemLayoutSizeFitting(
                        .init(
                            width: bounds.width,
                            height: UIView.layoutFittingCompressedSize.height
                        ),
                        withHorizontalFittingPriority: .required,
                        verticalFittingPriority: .fittingSizeLevel
                    )
                    
                    topOffset = size.height
                }
                
                if let footer = footerView {
                    let size = footer.systemLayoutSizeFitting(
                        .init(
                            width: bounds.width,
                            height: UIView.layoutFittingCompressedSize.height
                        ),
                        withHorizontalFittingPriority: .required,
                        verticalFittingPriority: .fittingSizeLevel
                    )
                    
                    bottomOffset = size.height
                }
                
                switch scrollView.contentInsetAdjustmentBehavior {
                case .never:
                    scrollView.contentInset = .init(top: topOffset, left: 0, bottom: bottomOffset, right: 0)
                default:
                    scrollView.contentInset = .init(
                        top: topOffset - safeAreaInsets.top,
                        left: 0,
                        bottom: bottomOffset - safeAreaInsets.bottom,
                        right: 0
                    )
                }
            }
            
            super.layoutSubviews()
        }
    }
}
