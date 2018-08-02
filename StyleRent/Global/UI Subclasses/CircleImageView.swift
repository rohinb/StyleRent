//
//  CircleImageView.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/29/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class CircleImageView: UIImageView {

	override func awakeFromNib() {
		layer.borderWidth = 1.0
		layer.masksToBounds = false
		layer.borderColor = UIColor.white.cgColor
		layer.cornerRadius = frame.size.height / 2
		clipsToBounds = true
	}

}
