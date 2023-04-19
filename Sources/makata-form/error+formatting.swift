//
//  File.swift
//  
//
//  Created by Michael Ong on 4/19/23.
//

import Foundation

public extension Sequence where Element == Error {
    var formatted: String {
        map({ $0.localizedDescription }).formatted(.list(type: .and))
    }
    
    func formatted(label: String) -> String {
        "\(label) \(formatted)"
    }
}
