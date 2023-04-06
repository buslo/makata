// view+uicollectionreusableview.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import UIKit

open class CollectionReusableView: UICollectionReusableView, ReusableRegisterable {
    open class var elementKind: String { fatalError() }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(
            generateTemplate()
                .defineConstraints { make in
                    make.edges
                        .equalToSuperview()
                }
        )
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open func generateTemplate() -> UIView {
        fatalError()
    }

    public func updateContent(_: IndexPath, _: String) {}
}
