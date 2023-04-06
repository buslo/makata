//
//  File.swift
//  
//
//  Created by Michael Ong on 3/12/23.
//

import Foundation
import UIKit
import SnapKit

public protocol ConstraintBuildable: AnyObject { }

extension UIView: ConstraintBuildable { }

public extension ConstraintBuildable where Self: UIView {
    @discardableResult
    func addSubview(_ viewWithConstraints: ConstructedViewWithConstraints<some UIView>) -> Self {
        addSubview(viewWithConstraints.view)
        viewWithConstraints.view.snp.makeConstraints(viewWithConstraints.constraint)

        return self
    }
    
    func defineConstraints(_ make: @escaping (ConstraintMaker) -> Void) -> ConstructedViewWithConstraints<Self> {
        .init(view: self, constraint: make)
    }
}

public struct ConstructedViewWithConstraints<View: UIView> {
    let view: View
    let constraint: (ConstraintMaker) -> Void
}
