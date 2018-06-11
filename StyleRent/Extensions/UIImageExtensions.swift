//
//  UIImageExtensions.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation

extension UIImage {

	func resizeImageWith(newSize: CGSize) -> UIImage {

		let horizontalRatio = newSize.width / size.width
		let verticalRatio = newSize.height / size.height

		let ratio = max(horizontalRatio, verticalRatio)
		let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
		UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
		draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage!
	}

}
