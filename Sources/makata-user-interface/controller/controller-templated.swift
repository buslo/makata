// controller-templated.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

open class ControllerTemplated<Template: UIView, Hook>: Controller<Hook> {
    public lazy var screenTemplate: Template = loadTemplate(frame: parent?.view.frame ?? .zero)

    override open var title: String? {
        didSet {
            guard isViewLoaded else {
                return
            }

            updateHeader()
        }
    }

    open var backAction: UIAction {
        .init { [unowned self] _ in
            guard let navigationController else {
                dismiss(animated: true)
                return
            }

            if navigationController.viewControllers.count == 1, navigationController.topViewController == self {
                navigationController.dismiss(animated: true)
            } else {
                navigationController.popViewController(animated: true)
            }
        }
    }

    open func loadTemplate(frame _: CGRect) -> Template {
        fatalError()
    }

    override open func loadView() {
        switch screenTemplate {
        case let pageView as Templates.PageView:
            addChild(pageView.hostingController)
            view = screenTemplate

            pageView.hostingController.didMove(toParent: self)
        default:
            view = screenTemplate
        }

        updateHeader()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let template = screenTemplate as? HasHeader {
            template.handleLayout()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        transitionCoordinator?.animate { [unowned self] context in
            if let template = screenTemplate as? HasHeader {
                template.handleLayout()
            }
        }
    }
  
//
//    open override func viewIsAppearing(_ animated: Bool) {
//        if let template = screenTemplate as? HasHeader {
//            template.handleLayout()
//        }
//
//        super.viewIsAppearing(animated)
//    }
//
    private func updateHeader() {
        if let template = screenTemplate as? HasHeader {
            template.headerView?.setupHeaderAppearance(title: title ?? "", backAction: backAction)
        }

        screenTemplate.setNeedsLayout()
        screenTemplate.layoutIfNeeded()
    }
}
