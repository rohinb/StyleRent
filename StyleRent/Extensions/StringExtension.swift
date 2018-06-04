//
//  StringExtension.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/27/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation

extension String {
	func toJSON() -> Any? {
		guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
		return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
	}
}
