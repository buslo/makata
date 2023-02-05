// protocol-cell-registerable.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import UIKit

public protocol CellRegisterable: AnyObject {
    associatedtype ItemType

    func updateContent(_ indexPath: IndexPath, _ item: ItemType)
}

public extension CellRegisterable where Self: UICollectionViewCell {
    static var Registration: UICollectionView.CellRegistration<Self, ItemType> {
        .init { cell, indexPath, itemIdentifier in
            cell.updateContent(indexPath, itemIdentifier)
        }
    }
}
