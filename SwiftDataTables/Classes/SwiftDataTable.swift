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

/// Array of DataTableValueType (data/reuseIdentifier)
//public typealias DataTableRow = [DataTableValueType]
public typealias DataTableRow = [DataTableValue]
/// Array of array of DataTableValue
public typealias DataTableContent = [DataTableRow]
public typealias DataTableViewModelContent = [[DataCellViewModel]]

public class SwiftDataTable: UIView {
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
    
    var options: DataTableConfiguration
    
    /// Array of custom collection view cell identifiers to map to columns of the spreadsheet.
    public var dataCells: [AnyClass]?

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
        return collectionView
    }()
    
    fileprivate(set) var layout: SwiftDataTableLayout? = nil {
        didSet {
            if let layout = layout {
                self.collectionView.collectionViewLayout = layout
                self.collectionView.reloadData()
            }
        }
    }
    
    fileprivate var dataStructure = DataStructureModel() {
        didSet {
            self.createDataCellViewModels(with: dataStructure)
        }
    }
    
    fileprivate(set) var headerViewModels = [DataHeaderFooterViewModel]()
    fileprivate(set) var footerViewModels = [DataHeaderFooterViewModel]()
    fileprivate var rowViewModels = DataTableViewModelContent() {
        didSet {
            self.searchRowViewModels = rowViewModels
        }
    }
    fileprivate var searchRowViewModels: DataTableViewModelContent!
    
    fileprivate var paginationViewModel: PaginationHeaderViewModel!
    fileprivate var menuLengthViewModel: MenuLengthHeaderViewModel!
    fileprivate var columnWidths = [CGFloat]()
        
    var rowCount: Int {
        return dataStructure.rowCount
    }
            
    //MARK: - Lifecycle
    public init(data: DataTableContent,
                columnWidths: [CGFloat],
                headerTitles: [String],
                options: DataTableConfiguration = DataTableConfiguration(),
                dataCells: [AnyClass] = [AnyClass](),
                frame: CGRect = .zero) {
        self.options = options
        self.columnWidths = columnWidths
        self.dataCells = dataCells
        super.init(frame: frame)
        self.set(data: data, columnWidths: columnWidths, headerTitles: headerTitles, options: options, shouldReplaceLayout: true)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationWillChange), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }
    
    public convenience init(data: [[String]],
                            columnWidths: [CGFloat],
                            headerTitles: [String],
                            options: DataTableConfiguration = DataTableConfiguration(),
                            dataCells: [AnyClass] = [AnyClass](),
                            frame: CGRect = .zero) {
        self.init(
            data: data.map { $0.map { DataTableValue(dataTableValue: .string($0), reuseIdentifier: "", widthOfString: 0.0) }},
            columnWidths: columnWidths,
            headerTitles: headerTitles,
            options: options,
            dataCells: dataCells,
            frame: frame
        )
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let headerIdentifier = String(describing: DataHeaderFooter.self)
        
        collectionView.register(DataHeaderFooter.self, forSupplementaryViewOfKind: SupplementaryViewType.columnHeader.rawValue, withReuseIdentifier: headerIdentifier)
        collectionView.register(DataHeaderFooter.self, forSupplementaryViewOfKind: SupplementaryViewType.footerHeader.rawValue, withReuseIdentifier: headerIdentifier)
        collectionView.register(PaginationHeader.self, forSupplementaryViewOfKind: SupplementaryViewType.paginationHeader.rawValue, withReuseIdentifier: String(describing: PaginationHeader.self))
        collectionView.register(MenuLengthHeader.self, forSupplementaryViewOfKind: SupplementaryViewType.searchHeader.rawValue, withReuseIdentifier: String(describing: MenuLengthHeader.self))
        collectionView.register(DataCell.self, forCellWithReuseIdentifier: String(describing: DataCell.self))
        
        // register custom collection view cells from calling app
        if let cells = dataCells {
            for cell in cells {
                collectionView.register(cell, forCellWithReuseIdentifier: String(describing: cell))
            }
        }
    }
    
    func set(data: DataTableContent, columnWidths: [CGFloat], headerTitles: [String], options: DataTableConfiguration? = nil, shouldReplaceLayout: Bool = false){
        self.columnWidths = columnWidths
        self.dataStructure = DataStructureModel(data: data, columnWidths: columnWidths, headerTitles: headerTitles)
        self.createDataCellViewModels(with: self.dataStructure)
        
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
        
        let numberOfColumns = dataSource?.numberOfColumns(in: self) ?? 0
        let numberOfRows = dataSource?.numberOfRows(in: self) ?? 0
        
        for columnIndex in 0..<numberOfColumns {
            guard let headerTitle = dataSource?.dataTable(self, headerTitleForColumnAt: columnIndex) else {
                return
            }
            headerTitles.append(headerTitle)
        }
        
        for index in 0..<numberOfRows {
            guard let rowData = self.dataSource?.dataTable(self, dataForRowAt: index) else {
                return
            }
            data.append(rowData)
        }
        self.layout?.clearLayoutCache()
        self.collectionView.resetScrollPositionToTop()
        self.set(data: data, columnWidths: columnWidths, headerTitles: headerTitles, options: self.options)
        self.collectionView.reloadData()
    }
    
    public func data(for indexPath: IndexPath) -> DataTableValueType {
        return rows[indexPath.section][indexPath.row].data
    }
}

public extension SwiftDataTable {
    func createDataModels(with data: DataStructureModel){
        self.dataStructure = data
    }
    
    func createDataCellViewModels(with dataStructure: DataStructureModel) {// -> DataTableViewModelContent {
        //1. Create the headers
        self.headerViewModels = Array(0..<(dataStructure.headerTitles.count)).map {
            let headerViewModel = DataHeaderFooterViewModel(
                data: dataStructure.headerTitles[$0],
                sortType: dataStructure.columnHeaderSortType(for: $0)
            )
            headerViewModel.configure(dataTable: self, columnIndex: $0)
            return headerViewModel
        }
        
        self.footerViewModels = Array(0..<(dataStructure.footerTitles.count)).map {
            let sortTypeForFooter = dataStructure.columnFooterSortType(for: $0)
            let headerViewModel = DataHeaderFooterViewModel(
                data: dataStructure.footerTitles[$0],
                sortType: sortTypeForFooter
            )
            return headerViewModel
        }
        
        //2. Create the view models
        //let viewModels: DataTableViewModelContent =
        self.rowViewModels = dataStructure.data.map { currentRowData in
            return currentRowData.map {
                return DataCellViewModel(data: $0.dataTableValue, reuseIdentifier: $0.reuseIdentifier, linkViewController: $0.linkViewControllerType, dataCellDelegate: $0.delegate)
            }
        }
        self.paginationViewModel = PaginationHeaderViewModel()
        self.menuLengthViewModel = MenuLengthHeaderViewModel()
        //        self.bindViewToModels()
    }
}

extension SwiftDataTable: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataSource = self.dataSource {
            return dataSource.numberOfColumns(in: self)
        }
        return self.dataStructure.columnCount
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        //if let dataSource = self.dataSource {
        //    return dataSource.numberOfRows(in: self)
        //}
        return self.numberOfRows()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellViewModel = self.rowModel(at: indexPath)
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellViewModel.reuseIdentifer, for: indexPath) as? DataCell else {
            fatalError("error in collection view cell")
        }
        cell.configure(cellViewModel)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsInLine: CGFloat = 6
        
        let inset = UIEdgeInsets.zero
        
        //        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        let minimumInteritemSpacing: CGFloat = 0
        let contentwidth: CGFloat = minimumInteritemSpacing * (numberOfItemsInLine - 1)
        let itemWidth = (collectionView.frame.width - inset.left - inset.right - contentwidth) / numberOfItemsInLine
        let itemHeight: CGFloat = 100
        
        return CGSize(width: itemWidth, height: itemHeight)
        
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        let kind = SupplementaryViewType(kind: elementKind)
        switch kind {
        case .paginationHeader:
            view.backgroundColor = UIColor.darkGray
        default:
            if #available(iOS 13.0, *) {
                view.backgroundColor = .systemBackground
            } else {
                view.backgroundColor = UIColor.white
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cellViewModel = self.rowModel(at: indexPath)
        
        if cellViewModel.highlighted {
            cell.contentView.backgroundColor = delegate?.dataTable?(self, highlightedColorForRowIndex: indexPath.item) ?? self.options.highlightedAlternatingRowColors[indexPath.section % self.options.highlightedAlternatingRowColors.count]
        }
        else {
            cell.contentView.backgroundColor = delegate?.dataTable?(self, unhighlightedColorForRowIndex: indexPath.item) ?? self.options.unhighlightedAlternatingRowColors[indexPath.section % self.options.unhighlightedAlternatingRowColors.count]
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let elementKind = SupplementaryViewType(kind: kind)
        let viewModel: CollectionViewSupplementaryElementRepresentable
        switch elementKind {
        case .searchHeader: viewModel = self.menuLengthViewModel
        case .columnHeader: viewModel = self.headerViewModels[indexPath.index]
        case .footerHeader: viewModel = self.footerViewModels[indexPath.index]
        case .paginationHeader: viewModel = self.paginationViewModel
        }
        return viewModel.dequeueView(collectionView: collectionView, viewForSupplementaryElementOfKind: kind, for: indexPath)
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItem?(self, indexPath: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.didDeselectItem?(self, indexPath: indexPath)
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

//MARK: - UICollection View Delegate
extension SwiftDataTable: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if(self.searchBar.isFirstResponder){
            self.searchBar.resignFirstResponder()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.disableScrollViewLeftBounce() {
            if (self.collectionView.contentOffset.x <= 0) {
                self.collectionView.contentOffset.x = 0
            }
        }
        if self.disableScrollViewTopBounce() {
            if (self.collectionView.contentOffset.y <= 0) {
                self.collectionView.contentOffset.y = 0
            }
        }
        if self.disableScrollViewRightBounce(){
            let maxX = self.collectionView.contentSize.width-self.collectionView.frame.width
            if (self.collectionView.contentOffset.x >= maxX){
                self.collectionView.contentOffset.x = max(maxX-1, 0)
            }
        }
        if self.disableScrollViewBottomBounce(){
            let maxY = self.collectionView.contentSize.height-self.collectionView.frame.height
            if (self.collectionView.contentOffset.y >= maxY){
                self.collectionView.contentOffset.y = maxY-1
            }
        }
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
}

//MARK: - Search Bar Delegate
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


extension SwiftDataTable {
    func set(options: DataTableConfiguration? = nil){
        self.layout = SwiftDataTableLayout(dataTable: self)
        self.rowViewModels = DataTableViewModelContent()
        self.paginationViewModel = PaginationHeaderViewModel()
        self.menuLengthViewModel = MenuLengthHeaderViewModel()
        //self.reload();
    }
}
