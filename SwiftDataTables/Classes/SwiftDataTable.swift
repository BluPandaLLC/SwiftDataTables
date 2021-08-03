//
//  SwiftDataTable.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 21/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import UIKit
import os.log

struct Log {
    static let osLog = OSLog(subsystem: "com.blupanda.swiftdatatable", category: "app")
}

protocol DataStructureViewModelFactory {
    func makeHeaderViewModels(fromDataStructure ds: DataStructureModel) -> [DataHeaderFooterViewModel]
    func makeFooterViewModles(fromDataStructure ds: DataStructureModel) -> [DataHeaderFooterViewModel]
    func makeRowViewModels(fromDataStructure ds: DataStructureModel) -> DataTableViewModelContent
}

/// Array of DataTableValueType (data/reuseIdentifier)
//public typealias DataTableRow = [DataTableValueType]
public typealias DataTableRow = [DataTableValue]
/// Array of array of DataTableValue
public typealias DataTableContent = [DataTableRow]
public typealias DataTableViewModelContent = [[DataCellViewModel]]

public class SwiftDataTable: UIView {
    /// enum indicating type of a supplemental view. Translates iOS `kind ` string to an enum.
    public enum SupplementaryViewType: String {
        /// Single header positioned at the top above the column section
        case paginationHeader = "SwiftDataTablePaginationHeader"
        
        /// Column header displayed at the top of each column
        case columnHeader = "SwiftDataTableViewColumnHeader"
        
        /// Footer displayed at the bottom of each column
        case footerHeader = "SwiftDataTableFooterHeader"
        
        /// Single header positioned at the bottom below the footer section.
        case searchHeader = "SwiftDataTableSearchHeader"
        
        init(kind: String){
            guard let elementKind = SupplementaryViewType(rawValue: kind) else {
                fatalError("Unknown supplementary view type passed in: \(kind)")
            }
            self = elementKind
        }
    }
    
    public weak var dataSource: SwiftDataTableDataSource?
    public weak var delegate: SwiftDataTableDelegate?
    
    public var rows: DataTableViewModelContent {
        return self.currentRowViewModels
    }
    
    var options = DataTableConfiguration()
    
    /// Array of custom collection view cell identifiers to map to columns of the spreadsheet. Set with `[CellClass.self]`.
    public var dataCells: [AnyClass]?
    /// Required array of header cells. Must be one for each column
    public var headerCells = [AnyClass]()
    /// Required array of footer cells. Must be one for each column
    public var footerCells = [AnyClass]()

    //MARK: - Private Properties
    var currentRowViewModels: DataTableViewModelContent {
        get {
            return self.searchRowViewModels
        }
        set {
            self.searchRowViewModels = newValue
        }
    }
    
    fileprivate(set) open lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal;
        searchBar.placeholder = "Search";
        searchBar.delegate = self
        if #available(iOS 13.0, *) {
            searchBar.backgroundColor = .systemBackground
            searchBar.barTintColor = .label
        } else {
            searchBar.backgroundColor = .white
            searchBar.barTintColor = .white
        }
        
        self.addSubview(searchBar)
        return searchBar
    }()
    
    //Lazy var
    fileprivate(set) open lazy var collectionView: UICollectionView = {
        os_log(.default, log: Log.osLog, "Creating collectionView")
        guard let layout = self.layout else {
            fatalError("The layout needs to be set first")
        }
        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = UIColor.systemBackground
        } else {
            collectionView.backgroundColor = UIColor.clear
        }
        collectionView.allowsMultipleSelection = true
        collectionView.dataSource = self
        collectionView.delegate = self
        if #available(iOS 10, *) {
            collectionView.isPrefetchingEnabled = false
        }
        self.addSubview(collectionView)

        self.registerCell(collectionView: collectionView)
        os_log(.default, log: Log.osLog, "Created collectionView")
        return collectionView
    }()
    
    fileprivate(set) var layout: SwiftDataTableLayout? = nil {
        didSet {
            if let layout = layout {
                os_log(.default, log: Log.osLog, "reloadData() from layout didSet")
                self.collectionView.collectionViewLayout = layout
                self.collectionView.reloadData()
            }
        }
    }
    
    var dataStructure = DataStructureModel()
    fileprivate(set) var headerViewModels = [DataHeaderFooterViewModel]()
    fileprivate(set) var footerViewModels = [DataHeaderFooterViewModel]()
    
    var rowViewModels = DataTableViewModelContent() {
        didSet {
            self.searchRowViewModels = rowViewModels
        }
    }
    
    var searchRowViewModels: DataTableViewModelContent!
    var paginationViewModel = PaginationHeaderViewModel()
    var menuLengthViewModel = MenuLengthHeaderViewModel()
    fileprivate var columnWidths = [CGFloat]()
        
    var rowCount: Int {
        return dataStructure.rowCount
    }
            
    //MARK: - Lifecycle
    public init(data: DataTableContent,
                columnWidths: [CGFloat],
                headerTitles: [String],
                footerTitles: [String],
                headerCells: [AnyClass],
                footerCells: [AnyClass],
                options: DataTableConfiguration = DataTableConfiguration(),
                dataCells: [AnyClass] = [AnyClass](),
                frame: CGRect = .zero) {
        os_log(.default, log: Log.osLog, "init() with DataTableContent")
        if headerTitles.count != headerCells.count {
            os_log(.fault, log: Log.osLog, "headerCell count (%i) not equal to headerTitle count (%i))", headerCells.count, headerTitles.count)
            fatalError("headerCell count (\(headerCells.count)) not equal to headerTitle count (\(headerTitles.count))")
        }

        if footerTitles.count != footerCells.count {
            os_log(.fault, log: Log.osLog, "footerCell count (%i) not equal to footerTitle count (%i))", footerCells.count, footerTitles.count)
            fatalError("footerCell count (\(footerCells.count)) not equal to footerTitle count (\(footerTitles.count))")
        }

        if footerTitles.count != headerTitles.count {
            os_log(.fault, log: Log.osLog, "headerTitles count (%i) not equal to footerTitle count (%i))", headerTitles.count, footerTitles.count)
            fatalError("headerTitles count (\(headerTitles.count)) not equal to footerTitle count (\(footerTitles.count))")
        }

        self.options = options
        self.columnWidths = columnWidths
        self.dataCells = dataCells
        self.headerCells = headerCells
        self.footerCells = footerCells
        super.init(frame: frame)
        self.set(data: data, columnWidths: columnWidths, headerTitles: headerTitles, footerTitles: footerTitles, options: options, shouldReplaceLayout: true)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationWillChange), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }
    
    public convenience init(data: [[String]],
                            columnWidths: [CGFloat],
                            headerTitles: [String],
                            footerTitles: [String],
                            headerCells: [AnyClass],
                            footerCells: [AnyClass],
                            options: DataTableConfiguration = DataTableConfiguration(),
                            dataCells: [AnyClass] = [AnyClass](),
                            frame: CGRect = .zero) {
        os_log(.default, log: Log.osLog, "init() with [[Any]")
        self.init(
            data: data.map { $0.map { DataTableValue(dataTableValue: .string($0), reuseIdentifier: "", widthOfString: 0.0) }},
            columnWidths: columnWidths,
            headerTitles: headerTitles,
            footerTitles: footerTitles,
            headerCells: headerCells,
            footerCells: footerCells,
            options: options,
            dataCells: dataCells,
            frame: frame
        )
    }
    
    public func initialize(data: DataTableContent,
                           columnWidths: [CGFloat],
                           headerTitles: [String],
                           footerTitles: [String],
                           headerCells: [AnyClass],
                           footerCells: [AnyClass],
                           options: DataTableConfiguration = DataTableConfiguration(),
                           dataCells: [AnyClass] = [AnyClass](),
                           frame: CGRect = .zero) {
        self.options = options
        self.columnWidths = columnWidths
        self.dataCells = dataCells
        self.headerCells = headerCells
        self.footerCells = footerCells
        self.set(data: data, columnWidths: columnWidths, headerTitles: headerTitles, footerTitles: footerTitles, options: options, shouldReplaceLayout: true)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationWillChange), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let searchBarHeight = self.heightForSearchView()
        self.searchBar.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: searchBarHeight)
        self.collectionView.frame = CGRect(x: 0, y: searchBarHeight, width: self.bounds.width, height: self.bounds.height-searchBarHeight)
    }
        
    @objc func deviceOrientationWillChange() {
        self.layout?.clearLayoutCache()
    }
    
    //TODO: Abstract away the registering of classes so that a user can register their own nibs or classes.
    /// Register custom collection cell views with the collection view. Includes header, footer, pagination header, search header, and custom cells supplied by calling app
    func registerCell(collectionView: UICollectionView){
        collectionView.register(PaginationHeader.self, forSupplementaryViewOfKind: SupplementaryViewType.paginationHeader.rawValue, withReuseIdentifier: String(describing: PaginationHeader.self))
        collectionView.register(MenuLengthHeader.self, forSupplementaryViewOfKind: SupplementaryViewType.searchHeader.rawValue, withReuseIdentifier: String(describing: MenuLengthHeader.self))
        
        collectionView.register(DataCell.self, forCellWithReuseIdentifier: String(describing: DataCell.self))
        
        
        // register custom collection view cells from calling app
        if let cells = dataCells {
            for cell in cells {
                collectionView.register(cell, forCellWithReuseIdentifier: String(describing: cell))
            }
        }
        // register header/footer cells
        registerOnlyUniqueCells(allCells: headerCells, forSupplementaryViewOfKind: SupplementaryViewType.columnHeader.rawValue, inCollectionView: collectionView)
        registerOnlyUniqueCells(allCells: footerCells, forSupplementaryViewOfKind: SupplementaryViewType.footerHeader.rawValue, inCollectionView: collectionView)
    }
    
    func registerOnlyUniqueCells(allCells cells: [AnyClass], forSupplementaryViewOfKind elementKind: String, inCollectionView cv: UICollectionView) {
        var uniqueCells = [AnyClass]()
        var seenCellStrings = Set<String>()
        for cell in cells {
            let cellString = String(describing: cell)
            if !seenCellStrings.contains(cellString) {
                uniqueCells.append(cell)
                seenCellStrings.insert(cellString)
            }
        }
        
        for cell in uniqueCells {
            cv.register(cell, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: String(describing: cell))
        }
    }
    
    func set(data: DataTableContent, columnWidths: [CGFloat], headerTitles: [String], footerTitles: [String], options: DataTableConfiguration? = nil, shouldReplaceLayout: Bool = false){
        os_log(.default, log: Log.osLog, "Running set()")
        self.columnWidths = columnWidths
        self.dataStructure = DataStructureModel(data: data, columnWidths: columnWidths, headerTitles: headerTitles, footerTitles: footerTitles, headerCells: headerCells, footerCells: footerCells)
        
        headerViewModels = makeHeaderViewModels(fromDataStructure: dataStructure)
        footerViewModels = makeFooterViewModles(fromDataStructure: dataStructure)
        rowViewModels = makeRowViewModels(fromDataStructure: dataStructure)
        
        if let options = options, let defaultOrdering = options.defaultOrdering {
            self.highlight(column: defaultOrdering.index)
            self.applyColumnOrder(defaultOrdering)
            self.sort(column: defaultOrdering.index, sort: self.headerViewModels[defaultOrdering.index].sortType)
        }
        
        if (shouldReplaceLayout) {
            self.layout = SwiftDataTableLayout(dataTable: self)
        }
    }
        
    public func reload(){
        var data = DataTableContent()
        var headerTitles = [String]()
        var footerTitles = [String()]
        
        let numberOfColumns = dataSource?.numberOfColumns(in: self) ?? 0
        let numberOfRows = dataSource?.numberOfRows(in: self) ?? 0
        
        for columnIndex in 0..<numberOfColumns {
            guard let headerTitle = dataSource?.dataTable(self, headerTitleForColumnAt: columnIndex) else {
                return
            }
            headerTitles.append(headerTitle)

            guard let footerTitle = dataSource?.dataTable(self, footerTitleForColumnAt: columnIndex) else {
                return
            }
            footerTitles.append(footerTitle)
        }
        
        for index in 0..<numberOfRows {
            guard let rowData = self.dataSource?.dataTable(self, dataForRowAt: index) else {
                return
            }
            data.append(rowData)
        }
        self.layout?.clearLayoutCache()
        self.collectionView.resetScrollPositionToTop()
        self.set(data: data, columnWidths: columnWidths, headerTitles: headerTitles, footerTitles: footerTitles, options: self.options)
        self.collectionView.reloadData()
    }
        public func data(for indexPath: IndexPath) -> DataTableValueType {
        return rows[indexPath.section][indexPath.row].data
    }
}


//MARK: - Swift Data Table Delegate
extension SwiftDataTable {
    func disableScrollViewLeftBounce() -> Bool {
        return true
    }
    func disableScrollViewTopBounce() -> Bool {
        return false
    }
    func disableScrollViewRightBounce() -> Bool {
        return true
    }
    func disableScrollViewBottomBounce() -> Bool {
        return false
    }
}

//MARK: - Refresh
extension SwiftDataTable {
    fileprivate func update(){
        self.layout?.clearLayoutCache()
        self.collectionView.reloadData()
    }
    
    func didTapColumn(index: IndexPath) {
        defer {
            self.update()
        }
        let index = index.index
        self.toggleSortArrows(column: index)
        self.highlight(column: index)
        let sortType = self.headerViewModels[index].sortType
        self.sort(column: index, sort: sortType)
    }
    
    func sort(column index: Int, sort by: DataTableSortType){
        func ascendingOrder(rowOne: [DataCellViewModel], rowTwo: [DataCellViewModel]) -> Bool {
            return rowOne[index].data < rowTwo[index].data
        }
        func descendingOrder(rowOne: [DataCellViewModel], rowTwo: [DataCellViewModel]) -> Bool {
            return rowOne[index].data > rowTwo[index].data
        }
        
        switch by {
        case .ascending:
            self.currentRowViewModels = self.currentRowViewModels.sorted(by: ascendingOrder)
        case .descending:
            self.currentRowViewModels = self.currentRowViewModels.sorted(by: descendingOrder)
        default:
            break
        }
    }
    
    func highlight(column: Int){
        self.currentRowViewModels.forEach {
            $0.forEach { $0.highlighted = false }
            $0[column].highlighted = true
        }
    }
    
    func applyColumnOrder(_ columnOrder: DataTableColumnOrder){
        Array(0..<self.headerViewModels.count).forEach {
            if columnOrder.index == $0 {
                self.headerViewModels[$0].sortType = columnOrder.order
            }
            else {
                self.headerViewModels[$0].sortType.toggleToDefault()
            }
        }
    }
    
    func toggleSortArrows(column: Int){
        Array(0..<self.headerViewModels.count).forEach {
            if column == $0 {
                self.headerViewModels[$0].sortType.toggle()
            }
            else {
                self.headerViewModels[$0].sortType.toggleToDefault()
            }
        }
    }
    
    //This is actually mapped to sections
    func numberOfRows() -> Int {
        return self.currentRowViewModels.count
    }
    func heightForRow(index: Int) -> CGFloat {
        return self.delegate?.dataTable?(self, heightForRowAt: index) ?? 44
    }
    
    func rowModel(at indexPath: IndexPath) -> DataCellViewModel {
        return self.currentRowViewModels[indexPath.section][indexPath.row]
    }
    
    func numberOfColumns() -> Int {
        return self.dataStructure.columnCount
    }
    
    func numberOfHeaderColumns() -> Int {
        return self.dataStructure.headerTitles.count
    }
    
    func numberOfFooterColumns() -> Int {
        return self.dataStructure.footerTitles.count
    }
    
    func shouldContentWidthScaleToFillFrame() -> Bool{
        return self.delegate?.shouldContentWidthScaleToFillFrame?(in: self) ?? self.options.shouldContentWidthScaleToFillFrame
    }
    
    func shouldSectionHeadersFloat() -> Bool {
        return self.delegate?.shouldSectionHeadersFloat?(in: self) ?? self.options.shouldSectionHeadersFloat
    }
    
    func shouldSectionFootersFloat() -> Bool {
        return self.delegate?.shouldSectionFootersFloat?(in: self) ?? self.options.shouldSectionFootersFloat
    }
    
    func shouldSearchHeaderFloat() -> Bool {
        return self.delegate?.shouldSearchHeaderFloat?(in: self) ?? self.options.shouldSearchHeaderFloat
    }
    
    func shouldShowSearchSection() -> Bool {
        return self.delegate?.shouldShowSearchSection?(in: self) ?? self.options.shouldShowSearchSection
    }
    
    func shouldShowFooterSection() -> Bool {
        return self.delegate?.shouldShowSearchSection?(in: self) ?? self.options.shouldShowFooter
    }
    
    func shouldShowPaginationSection() -> Bool {
        return false
    }
    
    func heightForSectionFooter() -> CGFloat {
        return self.delegate?.heightForSectionFooter?(in: self) ?? self.options.heightForSectionFooter
    }
    
    func heightForSectionHeader() -> CGFloat {
        return self.delegate?.heightForSectionHeader?(in: self) ?? self.options.heightForSectionHeader
    }
    
    func widthForColumn(index: Int) -> CGFloat {
        //May need to call calculateColumnWidths.. I want to deprecate it..
        guard let width = self.delegate?.dataTable?(self, widthForColumnAt: index) else {
            return self.columnWidths[index]
        }
        return width
    }
    
    func heightForSearchView() -> CGFloat {
        guard self.shouldShowSearchSection() else {
            return 0
        }
        return self.delegate?.heightForSearchView?(in: self) ?? self.options.heightForSearchView
    }
    
    func showVerticalScrollBars() -> Bool {
        return self.delegate?.shouldShowVerticalScrollBars?(in: self) ?? self.options.shouldShowVerticalScrollBars
    }
    
    func showHorizontalScrollBars() -> Bool {
        return self.delegate?.shouldShowHorizontalScrollBars?(in: self) ?? self.options.shouldShowHorizontalScrollBars
    }
    
    func heightOfInterRowSpacing() -> CGFloat {
        return self.delegate?.heightOfInterRowSpacing?(in: self) ?? self.options.heightOfInterRowSpacing
    }
    
    func widthForRowHeader() -> CGFloat {
        return 0
    }
        
    func calculateContentWidth() -> CGFloat {
        return Array(0..<self.numberOfColumns()).reduce(self.widthForRowHeader()) { $0 + self.widthForColumn(index: $1)}
    }
    
    
    func minimumColumnWidth() -> CGFloat {
        return 70
    }
    
    func minimumHeaderColumnWidth(index: Int) -> CGFloat {
      return CGFloat(self.dataStructure.headerTitles[index].widthOfString(usingFont: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)))
    }
    
    func heightForPaginationView() -> CGFloat {
        guard self.shouldShowPaginationSection() else {
            return 0
        }
        return 35
    }
    
    func fixedColumns() -> DataTableFixedColumnType? {
        return delegate?.fixedColumns?(for: self) ?? self.options.fixedColumns
    }
    
    func shouldSupportRightToLeftInterfaceDirection() -> Bool {
        return delegate?.shouldSupportRightToLeftInterfaceDirection?(in: self) ?? self.options.shouldSupportRightToLeftInterfaceDirection
    }
    
    func set(options: DataTableConfiguration? = nil){
        self.layout = SwiftDataTableLayout(dataTable: self)
        self.rowViewModels = DataTableViewModelContent()
        self.paginationViewModel = PaginationHeaderViewModel()
        self.menuLengthViewModel = MenuLengthHeaderViewModel()
        //self.reload();
    }
}
