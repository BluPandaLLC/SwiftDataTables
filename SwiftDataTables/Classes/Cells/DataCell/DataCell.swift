//
//  DataCell.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 22/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import UIKit
import os.log

public protocol DataCellDelegate {
    func didTap(forVC vc: UIViewController)
}

/// Subclass this to provide custom cells
open class DataCell: UICollectionViewCell {

    //MARK: - Properties
    open class Properties {
        public static let verticalMargin: CGFloat = 5
        public static let horizontalMargin: CGFloat = 15
        public static let widthConstant: CGFloat = 20
    }
    
    public let dataLabel = UILabel()
    public var delegate: DataCellDelegate?
    
    //MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setup() {
        dataLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dataLabel)
        NSLayoutConstraint.activate([
            dataLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: Properties.widthConstant),
            dataLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Properties.verticalMargin),
            dataLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Properties.verticalMargin),
            dataLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Properties.horizontalMargin),
            dataLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Properties.horizontalMargin),
        ])
    }
    
    open func configure(_ viewModel: DataCellViewModel) {
        os_log(.default, log: Log.osLog, "string: %@", viewModel.data.stringRepresentation)
        self.dataLabel.text = viewModel.data.stringRepresentation
//        self.contentView.backgroundColor = .white
    }
 }
