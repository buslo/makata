// view+uicontrol.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

public extension UIControl {
    private var touchUpInsideIdentifier: UIAction.Identifier {
        .init(rawValue: "guni_action_pressed")
    }

    @discardableResult
    func pressed(
        _ action: @escaping VoidCallbackAsync,
        showFailureOn failure: FailureCallable? = nil,
        showLoading: Bool = false,
        resetLoading: Bool = true
    ) -> Self {
        removeAction(identifiedBy: touchUpInsideIdentifier, for: .touchUpInside)

        addAction(UIAction(identifier: touchUpInsideIdentifier) { [unowned self, weak failure] _ in
            if showLoading {
                if let loadable = self as? ButtonLoadable {
                    loadable.isLoading = true
                } else {
                    isEnabled = false
                }
            }

            Task { @MainActor in
                do {
                    try await action()
                } catch {
                    failure?.showFailure(error)

                    if let loadable = self as? ButtonLoadable {
                        loadable.isLoading = false
                    } else {
                        isEnabled = true
                    }
                }

                if resetLoading {
                    if let loadable = self as? ButtonLoadable {
                        loadable.isLoading = false
                    } else {
                        isEnabled = true
                    }
                }
            }
        }, for: .touchUpInside)

        return self
    }
}
