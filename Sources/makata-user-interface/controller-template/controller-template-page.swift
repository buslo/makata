// controller-template-page.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import SnapKit
import UIKit

public extension Templates {
    final class Page: UIView, HasHeader {
        public enum KeyboardInsetBehavior {
            case normal
            case ignore
        }
        
        weak var headerVisualEffectView: UIVisualEffectView!
        
        public private(set) weak var headerView: (UIView & ViewHeader)?
        public private(set) weak var footerView: UIView?
        
        public private(set) weak var contentView: UIView!
        public private(set) weak var contentContainerView: UIScrollView!
        
        public var keyboardInsetBehavior = KeyboardInsetBehavior.ignore {
            didSet {
                setNeedsLayout()
            }
        }

        public lazy var contentViewLayoutGuide: UILayoutGuide = {
            let layoutGuide = UILayoutGuide()
            addLayoutGuide(layoutGuide)

            return layoutGuide
        }()

        public init(
            frame: CGRect,
            header: __owned UIView & ViewHeader,
            footer: __owned UIView? = nil,
            content: __owned UIView
        ) {
            super.init(frame: frame)

            if content is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }
            
            headerView = header
            footerView = footer
            contentView = content
            
            addSubview(UIScrollView().assign(to: &contentContainerView))
            addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .regular)).assign(to: &headerVisualEffectView))
            
            headerVisualEffectView.contentView.addSubview(view: UIView().backgroundColor(.separator)) { make in
                make.horizontalEdges
                    .bottom
                    .equalToSuperview()
                
                make.height
                    .equalTo(1 / UIScreen.main.scale)
            }
            
            setupHeaderLayout()
            setupFooterLayout()
            setupContentLayout()
            
            addSubview(header)
            
            if let footer {
                addSubview(footer)
            }
            
            contentContainerView.delegate = self
            contentContainerView.contentInsetAdjustmentBehavior = .never
            
            contentContainerView.addSubview(content)
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }
        
        public override func layoutSubviews() {
            setupHeaderLayout()
            setupFooterLayout()
            setupContentLayout()
            
            super.layoutSubviews()
        }
        
        public override func didMoveToSuperview() {
            super.didMoveToSuperview()
            
            guard superview != nil else {
                return
            }
            
            layoutIfNeeded()
            updateConstraintsIfNeeded()
            
            // Explicitly set content offset to mitigate bug that
            // makes the content go under the header.
            contentContainerView.contentOffset = .init(x: 0, y: -contentContainerView.contentInset.top)
        }
        
        func setupHeaderLayout() {
            guard let headerView else {
                return
            }

            let headerSize = headerView.systemLayoutSizeFitting(
                .init(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )

            headerView.frame = .init(
                origin: .init(
                    x: 0,
                    y: safeAreaInsets.top
                ),
                size: .init(
                    width: headerSize.width,
                    height: headerSize.height
                )
            )
            
            headerVisualEffectView.frame = .init(
                origin: .init(
                    x: 0,
                    y: 0
                ),
                size: .init(
                    width: bounds.width,
                    height: safeAreaInsets.top + headerSize.height
                )
            )
        }
        
        func setupFooterLayout() {
            guard let footerView else {
                return
            }
            
            let footerSize = footerView.systemLayoutSizeFitting(
                .init(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )

            footerView.frame = .init(
                origin: .zero,
                size: .init(
                    width: footerSize.width,
                    height: footerSize.height + safeAreaInsets.bottom
                )
            )
        }
        
        func setupContentLayout() {
            let headerHeight = headerView!.systemLayoutSizeFitting(
                .init(
                    width: bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height + safeAreaInsets.top
            
            let footerHeight = footerView?.systemLayoutSizeFitting(
                .init(
                    width: bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height ?? 0 + safeAreaInsets.bottom
            
            if let contentView {
                let contentSize = contentView.systemLayoutSizeFitting(
                    .init(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )

                let contentHeight = max(bounds.height - (headerHeight + footerHeight + 1), contentSize.height)
                let finalContentSize = CGSize(width: bounds.width, height: contentHeight)

                contentView.frame = .init(origin: .zero, size: finalContentSize)
                contentContainerView.contentSize = finalContentSize
            }

            contentContainerView.frame = bounds
            contentContainerView.contentInset = .init(
                top: ceil(headerHeight),
                left: 0,
                bottom: ceil(footerHeight),
                right: 0
            )
            contentContainerView.scrollIndicatorInsets = .init(
                top: ceil(headerHeight - safeAreaInsets.top),
                left: 0,
                bottom: ceil(footerHeight - safeAreaInsets.bottom),
                right: 0
            )
        }
    }
}

extension Templates.Page: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let headerHeight = safeAreaInsets.top + headerView!.bounds.height
        headerVisualEffectView.isHidden = (headerHeight + scrollView.contentOffset.y) <= 0
    }
}

extension Templates.Page {
    @discardableResult
    public func keyboardInsetBehavior(_ behavior: KeyboardInsetBehavior) -> Self {
        self.keyboardInsetBehavior = behavior
        
        return self
    }
}
