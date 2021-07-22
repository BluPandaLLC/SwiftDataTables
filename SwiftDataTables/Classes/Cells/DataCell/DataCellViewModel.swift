//
//  DataCellViewModel.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 22/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import Foundation
import UIKit
import os.log

/// One of these per DataCell. Initialize with DataTableValueType and reuseIdentifier
open class DataCellViewModel: CollectionViewCellRepresentable {
    
    //MARK: - Public Properties
    public let data: DataTableValueType
    /// identifies what cell type to dequeue
    public let reuseIdentifer: String
    /// Used by `LinkCell` to know what `UIViewController` type to instantiate.
    public let linkViewControllerType: UIViewController.Type?
    /// Used by `LinkCell` to provide view controller from which to push the link view controller
    public let delegate: DataCellDelegate?
    
    var highlighted: Bool = false

    public var stringRepresentation: String {
        return self.data.stringRepresentation
    }
    
    //MARK: - Lifecycle
    init(data: DataTableValueType, reuseIdentifier id: String, linkViewController lvct: UIViewController.Type? = nil, dataCellDelegate del: DataCellDelegate? = nil){
        self.data = data
        reuseIdentifer = id
        linkViewControllerType = lvct
        delegate = del
    }
}

extension DataCellViewModel: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: DataCellViewModel, rhs: DataCellViewModel) -> Bool {
        return lhs.data == rhs.data
        && lhs.highlighted == rhs.highlighted
    }

}
