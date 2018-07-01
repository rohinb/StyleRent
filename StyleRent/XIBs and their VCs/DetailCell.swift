//
//  FilterCell.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/1/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class DetailCell: UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
