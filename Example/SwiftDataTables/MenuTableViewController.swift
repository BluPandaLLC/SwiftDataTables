//
//  MenuTableViewController.swift
//  SwiftDataTables_Example
//
//  Created by Pavan Kataria on 13/06/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SwiftDataTables

struct MenuItem {
    let title: String
    let config: DataTableConfiguration?
    
    public init(title: String, config: DataTableConfiguration? = nil){
        self.title = title
        self.config = config
    }
}
class MenuViewController: UITableViewController {
    private enum Properties {
        enum Section {
            static let dataStore: Int = 0
            static let visualConfiguration: Int = 1
        }
        static let menuItemIdentifier: String = "MenuItemIdentifier"
    }
//    lazy var exampleConfigurations: [menuItems] = self.createdExampleConfigurations()
    
    lazy var menuItems: [[MenuItem]] = self.createdMenuItems()
    lazy var exampleConfigurations: [MenuItem] = self.createdExampleConfigurations()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Properties.menuItemIdentifier)
        tableView.rowHeight = 100
        self.tableView.reloadData()
    }
    //MARK: - Actions
    private func showDataStoreWithDataSet(){
        let instance = DataTableWithDataSetViewController()
        self.show(instance, sender: self)
    }
    private func showDataStoreWithDataSource(){
        let instance = DataTableWithDataSourceViewController()
        self.show(instance, sender: self)
    }
    private func showGenericExample(for index: Int){
        let menuItem = self.exampleConfigurations[index]
        guard let configuration = menuItem.config else {
            return
        }
        self.showGenericExample(with: configuration)
    }
    private func showGenericExample(with configuration: DataTableConfiguration){
        let instance = GenericDataTableViewController(with: configuration)
        self.show(instance, sender: self)
    }
}

class GenericDataTableViewController: UIViewController {
    
    var dataTable: SwiftDataTable! = nil
    let configuration: DataTableConfiguration
    
    public init(with configuration: DataTableConfiguration){
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        self.title = "Employee Balances"
        self.view.backgroundColor = UIColor.white
        self.dataTable = SwiftDataTable(
            data: self.data(),
            headerTitles: self.columnHeaders(),
            options: self.configuration
        )
        self.automaticallyAdjustsScrollViewInsets = false
        self.dataTable.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.dataTable.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.dataTable.frame = self.view.frame
        self.view.addSubview(self.dataTable);
    }
    func columnHeaders() -> [String] {
        return [
            "Id",
            "Name",
            "Email",
            "Number",
            "City",
            "Balance"
        ]
    }
    
    func data() -> [[DataTableValueType]]{
        return exampleDataSet().map {
            $0.compactMap (DataTableValueType.init)
        }
    }
}
//MARK: - Data source and delegate methods
extension MenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.menuItems.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuItems[section].count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Properties.menuItemIdentifier, for: indexPath)
        cell.textLabel?.text = self.menuItems[indexPath.section][indexPath.row].title
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Properties.Section.dataStore:
            return "Data Store variations"
        case Properties.Section.visualConfiguration:
            return "Visual configuration variations"
        default: return nil
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            showDataStoreWithDataSet()
        case (0,1):
            showDataStoreWithDataSource()
        case (1, let row):
            showGenericExample(for: row)
        default: fatalError("An example hasn't been created for [section: \(indexPath.section) row: \(indexPath.row)]")
        }
    }
}
//MARK: - Lazily Load
extension MenuViewController {
    private func createdMenuItems() -> [[MenuItem]] {
        let sectionOne: [MenuItem] = [
            MenuItem(title: "Initialised with Data Set"),
            MenuItem(title: "Initialised with Data Source")]
        let sectionTwo = self.exampleConfigurations
        
        return [sectionOne, sectionTwo]
    }
    private func createdExampleConfigurations() -> [MenuItem] {
        var section = [MenuItem]()
        section.append(MenuItem(title: "Without Footers", config: self.configurationWithoutFooter()))
        return section
    }
}

// MARK: - Configuration Examples
extension MenuViewController {
    private func configurationWithoutFooter() -> DataTableConfiguration {
        var configuration = DataTableConfiguration()
        configuration.shouldShowFooter = false
        return configuration
    }
}
