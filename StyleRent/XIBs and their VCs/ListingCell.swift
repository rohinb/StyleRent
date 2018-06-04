//
//  ListingCell.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/26/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3

class ListingCell: UITableViewCell {
	@IBOutlet weak var listingImageView: UIImageView!
	@IBOutlet weak var listingName: UILabel!

	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
