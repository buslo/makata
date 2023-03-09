// controller-template-page.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import SnapKit
import UIKit
import Combine

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

        var keyboardEvents = Set<AnyCancellable>()
        var keyboardInsets = UIEdgeInsets.zero {
            didSet {
                setNeedsLayout()
            }
        }
        
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
            
            setupKeyboardEvents()
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
        
        func setupKeyboardEvents() {
            NotificationCenter.default
                .publisher(for: UIApplication.keyboardWillShowNotification)
                .sink { [unowned self] notif in
                    guard let duration = notif
                        .userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                        return
                    }
                    
                    guard let curve = notif
                        .userInfo?[UIApplication.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
                        return
                    }
                    
                    guard let frame = notif
                        .userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? NSValue else {
                        return
                    }
                    
                    switch keyboardInsetBehavior {
                    case .normal:
                        keyboardInsets = .init(
                            top: 0,
                            left: 0,
                            bottom: frame.cgRectValue.height,
                            right: 0
                        )
                    case .ignore:
                        keyboardInsets = .zero
                    }
                    
                    UIView.animate(
                        withDuration: duration.doubleValue,
                        delay: 0,
                        options: UIView.AnimationOptions(rawValue: curve.uintValue << 16)
                    ) { [unowned self] in
                        layoutIfNeeded()
                    }
                }
                .store(in: &keyboardEvents)
            
            NotificationCenter.default
                .publisher(for: UIApplication.keyboardWillHideNotification)
                .sink { [unowned self] notif in
                    guard let duration = notif
                        .userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                        return
                    }
                    
                    guard let curve = notif
                        .userInfo?[UIApplication.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
                        return
                    }
                    
                    keyboardInsets = .zero
                    
                    UIView.animate(
                        withDuration: duration.doubleValue,
                        delay: 0,
                        options: UIView.AnimationOptions(rawValue: curve.uintValue << 16)
                    ) { [unowned self] in
                        layoutIfNeeded()
                    }
                }
                .store(in: &keyboardEvents)
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
            ).inset(by: keyboardInsets)
        }
        
        func setupContentLayout() {
            let bottomInset = keyboardInsets.bottom > 0 ? 0 : safeAreaInsets.bottom
            
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
            ).height ?? 0 + bottomInset
            
            if let contentView {
                let contentSize = contentView.systemLayoutSizeFitting(
                    .init(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )

                let contentHeight = max(
                    bounds.height - (headerHeight + footerHeight + 1 + keyboardInsets.bottom),
                    contentSize.height
                )

                let finalContentSize = CGSize(width: bounds.width, height: contentHeight)

                contentView.frame = .init(origin: .zero, size: finalContentSize)
                contentContainerView.contentSize = finalContentSize
            }

            contentContainerView.frame = bounds.inset(by: keyboardInsets)
            contentContainerView.contentInset = .init(
                top: ceil(headerHeight),
                left: 0,
                bottom: ceil(footerHeight),
                right: 0
            )
            contentContainerView.scrollIndicatorInsets = .init(
                top: ceil(headerHeight - safeAreaInsets.top),
                left: 0,
                bottom: ceil(footerHeight - bottomInset),
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
