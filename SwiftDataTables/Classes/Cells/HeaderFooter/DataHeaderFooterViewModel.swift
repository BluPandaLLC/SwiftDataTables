//
//  DataHeaderFooterViewModel.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 22/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import Foundation
import UIKit


public class DataHeaderFooterViewModel: DataTableSortable {

    //MARK: - Properties
    public let data: String
    var indexPath: IndexPath! // Questionable
    var dataTable: SwiftDataTable!
    public var reuseIdentifier: String? = nil
    public var headerFooterCell: AnyClass? = nil
    
    public var sortType: DataTableSortType
    
    var imageStringForSortingElement: String? {
        switch self.sortType {
        case .hidden:
            return nil
        case .unspecified:
            return "column-sort-unspecified"
        case .ascending:
            return "column-sort-ascending"
        case .descending:
            return "column-sort-descending"
        }
    }
    
    public var imageForSortingElement: UIImage? {
        guard let imageName = self.imageStringForSortingElement else {
            return nil
        }
        let bundle = Bundle(for: DataHeaderFooter.self)
        guard
            let url = bundle.url(forResource: "SwiftDataTables", withExtension: "bundle"),
            let imageBundle = Bundle(url: url),
            let imagePath = imageBundle.path(forResource: imageName, ofType: "png"),
            let image = UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysTemplate)
            else {
            return nil
        }
        return image
    }
    
    public var tintColorForSortingElement: UIColor? {
        return (dataTable != nil && sortType != .unspecified) ? dataTable.options.sortArrowTintColor : UIColor.gray
    }
    
    //MARK: - Events
    
    //MARK: - Lifecycle
    init(data: String, sortType: DataTableSortType? = .unspecified, reuseIdentifier rid: String? = nil, headerFooterCell hfc: AnyClass? = nil){
        self.data = data
        self.sortType = sortType!
        if let r = rid {
            reuseIdentifier = r
        }
        if let c = hfc {
            headerFooterCell = c
        }
    }
    
    public func configure(dataTable: SwiftDataTable, columnIndex: Int){
        self.dataTable = dataTable
        self.indexPath = IndexPath(index: columnIndex)
    }
}

//MARK: - Header View Representable
extension DataHeaderFooterViewModel: CollectionViewSupplementaryElementRepresentable {
    func dequeueView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        // Needs to dequeue a custom header/footer cell
        if reuseIdentifier == nil {
            reuseIdentifier = String(describing: DataHeaderFooter.self)
        }
        guard
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier!, for: indexPath) as? DataHeaderFooter
            else {
                return UICollectionReusableView()
        }
        
        headerView.configure(viewModel: self)
        switch kind {
        case SwiftDataTable.SupplementaryViewType.columnHeader.rawValue:
            headerView.didTapEvent = { [weak self] in
                self?.headerViewDidTap()
            }
        case SwiftDataTable.SupplementaryViewType.footerHeader.rawValue:
            break
        default:
            break
        }
        return headerView
    }
    
    //MARK: - Events
    func headerViewDidTap(){
        self.dataTable.didTapColumn(index: self.indexPath)
    }
}
