//
//  SortTypeImages.swift
//  
//
//  Created by Ted Conley on 8/4/21.
//

import UIKit

struct SortTypeImages {
    var unspecified = UIImage(systemName: "arrow.up.arrow.down.square")
    var ascending = UIImage(systemName: "arrow.up.square")
    var descending = UIImage(systemName: "arrow.down.square")

    static let shared = SortTypeImages()
    
    init() {}
    
    init(unspecified u: UIImage, ascending a: UIImage, descending d: UIImage) {
        unspecified = u
        ascending = a
        descending = d
    }
}
