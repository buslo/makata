// controller-templated.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

open class ControllerTemplated<Template: UIView, Hook>: Controller<Hook> {
    public lazy var screenTemplate: Template = loadTemplate()

    open func loadTemplate() -> Template {
        fatalError()
    }

    override open func loadView() {
        view = screenTemplate
    }
}
