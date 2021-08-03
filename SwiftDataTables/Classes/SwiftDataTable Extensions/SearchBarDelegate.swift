//
//  File.swift
//  
//
//  Created by Ted Conley on 7/31/21.
//

import UIKit

extension SwiftDataTable: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.executeSearch(searchText)
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    //TODO: Use Regular expression isntead
    private func filteredResults(with needle: String, on originalArray: DataTableViewModelContent) -> DataTableViewModelContent {
        var filteredSet = DataTableViewModelContent()
        let needle = needle.lowercased()
        Array(0..<originalArray.count).forEach{
            let row = originalArray[$0]
            //Add some sort of index array so we use that to iterate through the columns
            //The idnex array will be defined by the column definition inside the configuration object provided by the user
            //Index array might look like this [1, 3, 4]. Which means only those columns should be searched into
            for item in row {
                let stringData: String = item.data.stringRepresentation.lowercased()
                if stringData.lowercased().range(of: needle) != nil{
                    filteredSet.append(row)
                    //Stop searching through the rest of the columns in the same row and break
                    break;
                }
            }
        }
        
        return filteredSet
    }
    
    
    fileprivate func executeSearch(_ needle: String){
        let oldFilteredRowViewModels = self.searchRowViewModels!
        
        if needle.isEmpty {
            //DONT DELETE ORIGINAL CACHE FOR LAYOUTATTRIBUTES
            //MAYBE KEEP TWO COPIES.. ONE FOR SEARCH AND ONE FOR DEFAULT
            self.searchRowViewModels = self.rowViewModels
        }
        else {
            self.searchRowViewModels = self.filteredResults(with: needle, on: self.rowViewModels)
            //            print("needle: \(needle), rows found: \(self.searchRowViewModels!.count)")
        }
        self.layout?.clearLayoutCache()
        //        self.collectionView.scrollToItem(at: IndexPath(0), at: UICollectionViewScrollPosition.top, animated: false)
        //So the header view doesn't flash when user is at the bottom of the collectionview and a search result is returned that doesn't feel the screen.
        self.collectionView.resetScrollPositionToTop()
        self.differenceSorter(oldRows: oldFilteredRowViewModels, filteredRows: self.searchRowViewModels)
        
    }
    
    private func differenceSorter(
        oldRows: DataTableViewModelContent,
        filteredRows: DataTableViewModelContent,
        animations: Bool = false,
        completion: ((Bool) -> Void)? = nil) {
        
        UIView.setAnimationsEnabled(animations)
                
        collectionView.performBatchUpdates {
            //finding the differences
            
            //The currently displayed rows - in this case named old rows - is scanned over.. deleting any entries that are not existing in the newly created filtered list.
            for (oldIndex, oldRowViewModel) in oldRows.enumerated() {
                let index = self.searchRowViewModels.firstIndex { rowViewModel in
                    return oldRowViewModel == rowViewModel
                }
                
                if index == nil {
                    self.collectionView.deleteSections([oldIndex])
                }
            }
            
            //Iterates over the new search results and compares them with the current result set displayed - in this case name old - inserting any entries that are not existant in the currently displayed result set
            for (currentIndex, currentRolwViewModel) in filteredRows.enumerated() {
                let oldIndex = oldRows.firstIndex { oldRowViewModel in
                    return currentRolwViewModel == oldRowViewModel
                }
                
                if oldIndex == nil {
                    self.collectionView.insertSections([currentIndex])
                }
            }
        } completion: { finished in
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            if animations == false {
                UIView.setAnimationsEnabled(true)
            }
            completion?(finished)
        }
    }
}
