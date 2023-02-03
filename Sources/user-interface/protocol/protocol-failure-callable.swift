//
//  File.swift
//  
//
//  Created by Michael Ong on 2/3/23.
//

import Foundation

public protocol FailureCallable: AnyObject {
    func showFailure(_ error: Error)
}
