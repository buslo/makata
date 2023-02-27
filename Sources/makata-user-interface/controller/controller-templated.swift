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
            
            if let page = screenTemplate as? HasHeader {
                page.headerView?.setupHeaderAppearance(title: title ?? "", backAction: backAction)
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

        if let page = screenTemplate as? HasHeader {
            page.headerView?.setupHeaderAppearance(title: title ?? "", backAction: backAction)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let page = screenTemplate as? HasHeader, let headerView = page.headerView, page.headerAffectsLayout {
            let size = headerView.systemLayoutSizeFitting(
                .init(
                    width: view.bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            additionalSafeAreaInsets = .init(top: size.height - view.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
        }
    }
}
