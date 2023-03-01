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
        
        public private(set) weak var headerView: (UIView & ViewHeader)?
        public private(set) weak var footerView: UIView?
        
        public private(set) weak var contentView: UIView!
        
        weak var headerVisualEffectView: UIVisualEffectView!

        public var keyboardInsetBehavior = KeyboardInsetBehavior.ignore {
            didSet {
                remakeFooterConstraints()
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
            footer: __owned UIView = UIView(),
            content: __owned UIView,
            contentConstraints: (Page, ConstraintMaker) -> Void = { $1.edges.equalToSuperview() }
        ) {
            super.init(frame: frame)

            if content is UICollectionView {
                fatalError("Do not use this template. Use the Collection template instead.")
            }
            
            if let content = content as? UIScrollView {
                content.alwaysBounceVertical = true
            }

            headerView = header
            footerView = footer
            contentView = content

            addSubview(content)
            addSubview(header)
            addSubview(footer)

            insertSubview(
                UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                    .assign(to: &headerVisualEffectView),
                belowSubview: header
            )
            
            headerVisualEffectView.contentView.addSubview(
                view: UIView()
                    .backgroundColor(.separator)
            ) { make in
                make.horizontalEdges
                    .bottom
                    .equalToSuperview()

                make.height
                    .equalTo(1 / UIScreen.main.scale)
            }

            header.snp.contentHuggingVerticalPriority = UILayoutPriority.required.rawValue
            footer.snp.contentHuggingVerticalPriority = UILayoutPriority.required.rawValue

            content.snp.contentCompressionResistanceVerticalPriority = UILayoutPriority.required.rawValue

            content.snp.makeConstraints { make in
                contentConstraints(self, make)
            }

            headerView?.snp.makeConstraints { make in
               make.top
                   .horizontalEdges
                   .equalToSuperview()
            }
            
            headerVisualEffectView.snp.makeConstraints { make in
                make.edges
                    .equalTo(header)
            }

            remakeFooterConstraints()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            
            updateScrollViewInsets()
        }
        
        @discardableResult
        public func keyboardInsetBehavior(_ behavior: KeyboardInsetBehavior) -> Self {
            self.keyboardInsetBehavior = behavior
            
            return self
        }
        
        func remakeFooterConstraints() {
            footerView?.snp.remakeConstraints { make in
                switch keyboardInsetBehavior {
                case .normal:
                    make.horizontalEdges
                        .equalToSuperview()
                    
                    make.bottom
                        .equalTo(keyboardLayoutGuide.snp.top)
                case .ignore:
                    make.bottom
                        .horizontalEdges
                        .equalToSuperview()
                }
            }
            
            contentViewLayoutGuide.snp.remakeConstraints { make in
                make.top
                    .equalTo(headerView!.snp.bottom)

                make.horizontalEdges
                    .equalToSuperview()
                
                switch keyboardInsetBehavior {
                case .normal:
                    make.bottom
                        .equalTo(keyboardLayoutGuide.snp.top)
                        .priority(.required)
                    
                    make.bottom
                        .equalToSuperview()
                        .priority(999)
                case .ignore:
                    make.bottom
                        .equalToSuperview()
                }
            }
        }
        
        func updateScrollViewInsets() {
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
                    
                    topOffset = ceil(size.height)
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

                    bottomOffset = ceil(size.height)
                }
                
                switch scrollView.contentInsetAdjustmentBehavior {
                case .never:
                    scrollView.contentInset = .init(top: topOffset, left: 0, bottom: bottomOffset, right: 0)
                default:
                    let finalTopOffset = max(0, topOffset - safeAreaInsets.top)
                    let finalBottomOffset = max(0, bottomOffset - safeAreaInsets.bottom)

                    scrollView.contentInset = .init(top: finalTopOffset, left: 0, bottom: finalBottomOffset, right: 0)
                }
            }
        }
    }
}
