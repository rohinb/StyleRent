//
//  Globals.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation

var gblUser : User! {
	didSet {
		Defaults.standard.set(gblUser?._id, forKey: Defaults.userIdKey)
	}
}

enum ListingCategory : String {
	case jewelry = "Jewelry"
	case accessories = "Accessories"
	case bags = "Bags"
	case shoes = "Shoes"
	case dresses = "Dresses"
	case jacketsCoats = "Jackets & Coats"
	case jeans = "Jeans"
	case pants = "Pants"
	case shorts = "Shorts"
	case skirts = "Skirts"
	case sweaters = "Sweaters"
	case tops = "Tops"

	static let allValues : [ListingCategory] = [.jewelry, .accessories, .bags, .shoes, .dresses, .jacketsCoats, .jeans, .pants, .shorts, .skirts, .sweaters, .tops]
}

enum AuthType : String {
	case facebook = "Facebook"
	case google = "Google"
	case manual = "Manual Login"
}

class ListingDetail {
	var category : ListingCategory?
	var size : String?
}

struct ClothingUtils {
	static func getSizeOptions(for category : ListingCategory) -> [String] {
		switch category {
		case .jewelry, .accessories, .bags: return ["One Size"]
		case .shoes:
			return ["5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9", "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13", "13.5"]
		case .dresses, .jacketsCoats, .skirts, .tops, .sweaters:
			return ["00", "0", "2", "4", "6", "8", "10", "12", "XXS", "XS", "S", "M", "L", "XL", // Standard
				"00P", "0P", "2P", "4P", "6P", "8P", "10P", "12P", "14P", "16P", "18P", "20P", "XXSP", "XSP", "SP", "MP", "LP", "XLP", "XXLP"] // Petite
		case .jeans, .pants, .shorts:
			return ["23", "24", "25", "26", "27", "28", "29", "30", "31", "00", "0", "2", "4", "6", "8", "10", "12", "XXS", "XS", "S", "M", "L", "XL", "23P", "24P", "25P", "26P", "27P", "28P", "29P", "30P", "31P", "32P", "33P", "34P", "00P", "0P", "2P", "4P", "6P", "8P", "10P", "12P", "XXSP", "XSP", "SP", "MP", "LP", "XLP"]
		}
	}
}

struct Defaults {
	static let standard = UserDefaults.standard

	static let userIdKey = "user_id"
}
