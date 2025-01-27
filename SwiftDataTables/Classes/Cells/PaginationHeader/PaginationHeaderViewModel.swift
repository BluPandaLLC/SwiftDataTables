//
//  PaginationHeaderViewModel.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 03/03/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import Foundation
import UIKit

class PaginationHeaderViewModel {
    
}

extension PaginationHeaderViewModel: CollectionViewSupplementaryElementRepresentable {
    func dequeueView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let identifier = String(describing: PaginationHeader.self)
        guard
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier:
                identifier,
                for: indexPath
                ) as? PaginationHeader
            else {
                return UICollectionReusableView()
        }
        
        headerView.configure(self)
        return headerView
    }
}
