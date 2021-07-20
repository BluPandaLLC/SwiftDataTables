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
    var highlighted: Bool = false

    public var stringRepresentation: String {
        return self.data.stringRepresentation
    }
    
    //MARK: - Lifecycle
    init(data: DataTableValueType, reuseIdentifier id: String){
        self.data = data
        self.reuseIdentifer = id
    }

    static func registerCell(collectionView: UICollectionView) {
        let identifier = String(describing: DataCell.self)
        collectionView.register(DataCell.self, forCellWithReuseIdentifier: identifier)
        let nib = UINib(nibName: identifier, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
//        let identifier = String(describing: DataCell.self)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifer, for: indexPath) as? DataCell else {
            fatalError("error in collection view cell")
        }
        
        cell.configure(self)
        return cell
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
