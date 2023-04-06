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
        view = screenTemplate

        updateHeader()
    }

    private func updateHeader() {
        if let template = screenTemplate as? HasHeader {
            template.headerView?.setupHeaderAppearance(title: title ?? "", backAction: backAction)
        }

        screenTemplate.setNeedsLayout()
        screenTemplate.layoutIfNeeded()
    }
}
