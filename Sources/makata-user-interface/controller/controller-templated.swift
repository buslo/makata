// controller-templated.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

open class ControllerTemplated<Template: UIView, Hook>: Controller<Hook> {
    public lazy var screenTemplate: Template = loadTemplate()

    open override var title: String? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            if let page = screenTemplate as? Templates.Page {
                page.headerView.setupHeaderAppearance(title: title ?? "", backAction: backAction)
            }
        }
    }
    
    open var backAction: UIAction {
        .init { [unowned self] _ in
            navigationController?.popViewController(animated: true)
        }
    }

    open func loadTemplate() -> Template {
        fatalError()
    }

    override open func loadView() {
        view = screenTemplate

        if let page = screenTemplate as? Templates.Page {
            page.headerView.setupHeaderAppearance(title: title ?? "", backAction: backAction)
        }
    }
}
