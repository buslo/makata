// view+uicollectionviewcell.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import UIKit

open class CollectionViewCell<ItemType>: UICollectionViewCell, CellRegisterable {
    override public init(frame: CGRect) {
        super.init(frame: frame)

        contentView
            .addSubview(
                loadView()
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

    open func loadView() -> UIView {
        fatalError()
    }

    open func updateContent(_: IndexPath, _: ItemType) {}
}
