// controller-templated.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

open class ControllerTemplated<Template: UIView, Hook>: Controller<Hook> {
    public lazy var screenTemplate: Template = loadTemplate(frame: parent?.view.frame ?? .zero)

    open override var title: String? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            updateHeader()
        }
    }
    
    open var backAction: UIAction {
        .init { [unowned self] _ in
            navigationController?.popViewController(animated: true)
        }
    }

    open func loadTemplate(frame: CGRect) -> Template {
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

        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()

        view.setNeedsLayout()
        view.layoutSubviews()
    }
}
