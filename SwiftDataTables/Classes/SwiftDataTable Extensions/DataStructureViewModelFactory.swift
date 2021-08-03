//
//  File.swift
//  
//
//  Created by Ted Conley on 7/31/21.
//

import Foundation

extension SwiftDataTable: DataStructureViewModelFactory {
    func makeHeaderViewModels(fromDataStructure ds: DataStructureModel) -> [DataHeaderFooterViewModel] {
        var headerViewmodels = [DataHeaderFooterViewModel]()
        for i in 0..<ds.headerTitles.count {
            let headerViewmodel = DataHeaderFooterViewModel(data: ds.headerTitles[i],
                                                            reuseIdentifier: String(describing: ds.headerCells[i]),
                                                            headerFooterCell: ds.headerCells[i])
            headerViewmodel.configure(dataTable: self, columnIndex: i)
            headerViewmodels.append(headerViewmodel)
        }
        return headerViewmodels
    }
    
    func makeFooterViewModles(fromDataStructure ds: DataStructureModel) -> [DataHeaderFooterViewModel] {
        var footerViewModels = [DataHeaderFooterViewModel]()
        for i in 0..<ds.footerTitles.count {
            let footerViewModel = DataHeaderFooterViewModel(data: ds.footerTitles[i],
                                                            reuseIdentifier: String(describing: ds.footerCells[i]),
                                                            headerFooterCell: ds.footerCells[i])
            footerViewModel.configure(dataTable: self, columnIndex: i)
            footerViewModels.append(footerViewModel)
        }
        return footerViewModels
    }
    
    func makeRowViewModels(fromDataStructure ds: DataStructureModel) -> DataTableViewModelContent {
        return ds.data.map { currentRowData in
            return currentRowData.map {
                return DataCellViewModel(data: $0.dataTableValue, reuseIdentifier: $0.reuseIdentifier, linkViewController: $0.linkViewControllerType, dataCellDelegate: $0.delegate, searchKey: $0.searchKey)
            }
        }
    }
}
