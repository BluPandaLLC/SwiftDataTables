//
//  DataTableFixedColumnType.swift
//  SwiftDataTables_Example
//
//  Created by Pavan Kataria on 18/06/2019.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
import Foundation
public enum DataTableFixedColumnSideType {
    case left
    case right
}
public class DataTableFixedColumnType: NSObject {
    
    //MARK: - Properties
    let leftColumns: Int
    let rightColumns: Int

    //MARK: - Lifecycle
    public init(leftColumns: Int, rightColumns: Int){
        self.leftColumns = leftColumns
        self.rightColumns = rightColumns
    }
    
    public convenience init(leftColumns: Int) {
        self.init(leftColumns: leftColumns, rightColumns: 0)
    }
    
    public convenience init(rightColumns: Int) {
        self.init(leftColumns: 0, rightColumns: rightColumns)
    }
}

extension DataTableFixedColumnType {
    /// Not the UIKit hitTest. Return side of row header cell if the cell is within the bounds of the fixed column index
    public func hitTest(_ columnIndex: Int, totalTableColumnCount: Int) -> DataTableFixedColumnSideType? {
        if columnIndex < leftColumns {
            return .left
        }
        else if columnIndex >= totalTableColumnCount - rightColumns {
            return .right
        }
        return nil
    }
}
