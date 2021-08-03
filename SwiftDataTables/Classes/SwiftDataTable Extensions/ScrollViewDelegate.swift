//
//  ScrollViewDelegate.swift
//  
//
//  Created by Ted Conley on 7/31/21.
//

import UIKit

extension SwiftDataTable: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if(searchBar.isFirstResponder){
            searchBar.resignFirstResponder()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if disableScrollViewLeftBounce() {
            if (collectionView.contentOffset.x <= 0) {
                collectionView.contentOffset.x = 0
            }
        }
        
        if disableScrollViewTopBounce() {
            if (collectionView.contentOffset.y <= 0) {
                collectionView.contentOffset.y = 0
            }
        }
        
        if disableScrollViewRightBounce(){
            let maxX = collectionView.contentSize.width-collectionView.frame.width
            if (collectionView.contentOffset.x >= maxX){
                collectionView.contentOffset.x = max(maxX-1, 0)
            }
        }
        
        if disableScrollViewBottomBounce(){
            let maxY = collectionView.contentSize.height-collectionView.frame.height
            if (collectionView.contentOffset.y >= maxY){
                collectionView.contentOffset.y = maxY-1
            }
        }
    }
}
