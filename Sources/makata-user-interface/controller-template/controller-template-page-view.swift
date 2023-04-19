//
//  File.swift
//  
//
//  Created by Michael Ong on 4/19/23.
//

import Foundation
import SnapKit
import UIKit
import SwiftUI
import Combine

public extension Templates {
    final class PageView: UIView, HasHeader {
        public enum KeyboardInsetBehavior {
            case normal
            case ignore
        }

        weak var headerVisualEffectView: UIVisualEffectView!
        weak var headerBorderView: UIView!

        let hostingController: UIViewController!

        public private(set) weak var headerView: (UIView & ViewHeader)?
        public private(set) weak var footerView: UIView?

        public var keyboardInsetBehavior = KeyboardInsetBehavior.ignore {
            didSet {
                setNeedsLayout()
            }
        }

        public var showHairlineBorder = true {
            didSet {
                setNeedsLayout()
            }
        }

        var keyboardEvents = Set<AnyCancellable>()
        var keyboardInsets = UIEdgeInsets.zero {
            didSet {
                setNeedsLayout()
            }
        }

        public init<Content: View>(
            frame: CGRect,
            header: __owned UIView & ViewHeader,
            footer: __owned UIView? = nil,
            content: __owned UIHostingController<Content>
        ) {
            hostingController = content

            super.init(frame: frame)

            headerView = header
            footerView = footer

            addSubview(content.view)
            addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .regular)).assign(to: &headerVisualEffectView))

            headerVisualEffectView.contentView
                .addSubview(
                    UIView()
                        .backgroundColor(.separator)
                        .assign(to: &headerBorderView)
                        .defineConstraints  { make in
                            make.horizontalEdges
                                .bottom
                                .equalToSuperview()
                            
                            make.height
                                .equalTo(1 / UIScreen.main.scale)
                        }
                )

            setupKeyboardEvents()
            setupHeaderLayout()
            setupFooterLayout()
            setupContentLayout()

            addSubview(header)

            if let footer {
                addSubview(footer)
            }
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

            headerBorderView.isHidden = !showHairlineBorder

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
            let headerHeight = headerView!.systemLayoutSizeFitting(
                .init(
                    width: bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
            
            let footerHeight = footerView?.systemLayoutSizeFitting(
                .init(
                    width: bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height ?? 0
            
            hostingController.additionalSafeAreaInsets = .init(top: headerHeight, left: 0, bottom: footerHeight, right: 0)
            hostingController.view.frame = bounds
        }
    }
}

extension Templates.PageView {
    @discardableResult
    public func keyboardInsetBehavior(_ behavior: KeyboardInsetBehavior) -> Self {
        self.keyboardInsetBehavior = behavior
        
        return self
    }
}
