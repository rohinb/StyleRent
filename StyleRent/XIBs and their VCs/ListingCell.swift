//
//  ListingCell.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/7/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class ListingCell: UICollectionViewCell {
	@IBOutlet weak var listingImageView: UIImageView!
	@IBOutlet weak var sizeLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var listingNameLabel: UILabel!
	@IBOutlet weak var lenderNameLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.lightGray.cgColor
    }

}
