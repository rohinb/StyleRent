//
//  Utilities.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/8/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation

struct Utilities {
	private static let bucketName = "stylerentbackend-userfiles-mobilehub-1070684980"
	static func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		URLSession.shared.dataTask(with: url) { data, response, error in
			completion(data, response, error)
			}.resume()
	}

	static func getClosetVcFor(user: User) -> ListingsViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "ListingsVC") as! ListingsViewController
		vc.listingsOwnerName = user._name ?? user._id!
		vc.onlyMyListings = true
		vc.listingsOwnerId = user._id!
		return vc
	}

	static func getUrlForUserPicture(userId : String) -> URL {
		return URL(string: "https://\(bucketName).s3.amazonaws.com/profile-images/\(userId)")!
	}

	static func getUrlForListingPicture(listingId : String, imageNumber : Int) -> URL {
		return URL(string: "https://\(bucketName).s3.amazonaws.com/listing-images/\(listingId)-\(imageNumber)")!
	}

	static let dateFormatString = "MM/dd/yyyy"

	static func getApiDateFor(date : Date) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = dateFormatString
		let dateString = dateFormatter.string(from:date)
		return dateString
	}

	static func getDateFor(apiDate : String) -> Date {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = dateFormatString
		let date = dateFormatter.date(from: apiDate)
		return date!
	}
}
