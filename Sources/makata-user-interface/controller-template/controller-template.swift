// controller-template.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

public enum Templates {}

public protocol HasHeader: AnyObject {
    var headerView: (UIView & ViewHeader)? { get }
}
