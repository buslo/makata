// controller.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import makataInteraction
import UIKit

open class Controller<Hook>: UIViewController, Hookable {
    public var client: Hook

    public required init(hook: Hook) {
        client = hook

        super.init(nibName: nil, bundle: nil)

        configureController()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        if let loadable = client as? (any Loadable) {
            Task {
                await loadable.invalidate()
            }
        }
    }

    open func configureController() {}
}
