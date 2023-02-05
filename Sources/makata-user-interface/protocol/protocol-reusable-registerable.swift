// protocol-reusable-registerable.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import UIKit

public protocol ReusableRegisterable: AnyObject {
    static var elementKind: String { get }

    func updateContent(_ indexPath: IndexPath, _ elementKind: String)
}

public extension ReusableRegisterable where Self: UICollectionReusableView {
    static var Registration: UICollectionView.SupplementaryRegistration<Self> {
        .init(elementKind: elementKind) { supplementaryView, elementKind, indexPath in
            supplementaryView.updateContent(indexPath, elementKind)
        }
    }
}
