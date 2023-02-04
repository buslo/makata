// protocol-view-header.swift
//
// Code Copyright Buslo Collective
// Created 2/4/23

import Foundation
import UIKit

public protocol ViewHeader: AnyObject {
    func setupHeaderAppearance(title: String, backAction: UIAction?)
}
