//
//  MenuLengthHeaderViewModel.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 03/03/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import Foundation
import UIKit

class MenuLengthHeaderViewModel: NSObject {
    //MARK: - Events
    var searchTextFieldDidChangeEvent: ((String) -> Void)? = nil
}

extension MenuLengthHeaderViewModel: CollectionViewSupplementaryElementRepresentable {
    func dequeueView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let identifier = String(describing: MenuLengthHeader.self)
        guard
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier:
                identifier,
                for: indexPath
                ) as? MenuLengthHeader
            else {
                return UICollectionReusableView()
        }
        
        headerView.configure(self)
        return headerView
    }
}

extension MenuLengthHeaderViewModel {
    @objc func textFieldDidChange(textField: UITextField){
        guard let text = textField.text else {
            return
        }
        self.searchTextFieldDidChangeEvent?(text)
    }
}

extension MenuLengthHeaderViewModel: UISearchBarDelegate {
    
}
