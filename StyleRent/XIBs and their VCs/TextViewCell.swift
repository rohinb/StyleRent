//
//  TextViewCell.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/24/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class TextViewCell: UITableViewCell {

	@IBOutlet weak var field: UITextField!
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
