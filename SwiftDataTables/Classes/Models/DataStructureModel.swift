//
//  DataStructureModel.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 22/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import Foundation
import UIKit

//struct DataTableColumnModel {
//    
//}
/// DataTableContent (data), header/footer titles and some formatting info
public struct DataStructureModel {
    
    //MARK: - Private Properties
    private var shouldFitTitles: Bool = true
    var columnCount: Int {
        return headerTitles.count// ?? 0
    }
    
    var rowCount: Int {
        return data.count
    }
    
    //MARK: - Public Properties
    /// [[DataTableValueType]] (data/reuseIdentifier)
    var data = DataTableContent()
    var columnWidths = [CGFloat]()
    var headerTitles = [String]()
    var footerTitles = [String]()
    var shouldFootersShowSortingElement: Bool = false
    
    private var columnAverageContentLength = [Float]()
    
    //MARK: - Lifecycle
    init() {
        self.init(data: DataTableContent(), columnWidths: [CGFloat](), headerTitles: [String]())
    }
    
    init(data: DataTableContent,
         columnWidths: [CGFloat],
         headerTitles: [String],
         shouldMakeTitlesFitInColumn: Bool = true,
         shouldDisplayFooterHeaders: Bool = true) {
        self.columnWidths = columnWidths
        self.headerTitles = headerTitles
        
        let unfilteredData = data
        let sanitisedData = unfilteredData.filter({ currentRowData in
            //Trim column count for current row to the number of headers present
            let rowWithPreferredColumnCount = Array(currentRowData.prefix(upTo: self.columnCount))
            return rowWithPreferredColumnCount.count == self.columnCount
        })
        self.data = sanitisedData
        
        self.shouldFitTitles = shouldMakeTitlesFitInColumn
        self.columnAverageContentLength = self.processColumnDataAverages(data: self.data)
        
        if shouldDisplayFooterHeaders {
            self.footerTitles = headerTitles
        }
    }
    
    
    public func averageColumnDataLengthTotal() -> Float {
        return Array(0..<self.headerTitles.count).reduce(0){ $0 + self.averageDataLengthForColumn(index: $1) }
    }
    
    public func averageDataLengthForColumn(index: Int) -> Float {
        if self.shouldFitTitles {
            return max(self.columnAverageContentLength[index], Float(self.headerTitles[index].count))
        }
        return self.columnAverageContentLength[index]
    }

    //extension DataStructureModel {
    /// Finds the average content length in each column
    private func processColumnDataAverages(data: DataTableContent) -> [Float] {
        var columnContentAverages = [Float]()
        
        for column in Array(0..<self.headerTitles.count) {
            let averageForCurrentColumn = Array(0..<data.count).reduce(0) {
                let dataValue: DataTableValue = data[$1][column]
                return $0 + Int(dataValue.widthOfString.rounded(.up))
                return $0 + Int(dataValue.dataTableValue.stringRepresentation.widthOfString(usingFont: UIFont.systemFont(ofSize: UIFont.labelFontSize)).rounded(.up))
            }
            columnContentAverages.append((data.count == 0) ? 1 : Float(averageForCurrentColumn) / Float(data.count))
        }
        return columnContentAverages
    }
    
    public func columnHeaderSortType(for index: Int) -> DataTableSortType {
        guard self.headerTitles[safe: index] != nil else {
            return .hidden
        }
        //Check the configuration object to see what it wants us to display otherwise return default
        return .unspecified
    }

    public func columnFooterSortType(for index: Int) -> DataTableSortType {
        guard self.footerTitles[safe: index] != nil else {
            return .hidden
        }
        //Check the configuration object to see what it wants us to display otherwise return default
        return .hidden
    }
}
