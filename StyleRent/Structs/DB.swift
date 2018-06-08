//
//  File.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import AWSDynamoDB

/**
	Singleton class for calling DB methods. Delegate methods should always be called in Main Thread.
*/

class DB {
	private static var instance : DB?
	private let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
	var delegate : DBDelegate?

	static func shared() -> DB {
		if let instance = instance {
			return instance
		} else {
			let newDB = DB()
			instance = newDB
			return newDB
		}
	}

	init() {

	}

	func createUser(user : User) {
		
		dynamoDbObjectMapper.save(user, completionHandler: {
			(error: Error?) -> Void in

			DispatchQueue.main.async {
				if let error = error {
					self.delegate?.createUserResponse?(success: false, error: "Amazon DynamoDB Save Error: \(error)")
				}
				self.delegate?.createUserResponse?(success: true, error: nil)
			}
		})
	}

	func createListing(listing : Listing) {

		dynamoDbObjectMapper.save(listing, completionHandler: {
			(error: Error?) -> Void in

			DispatchQueue.main.async {
				if let error = error {
					self.delegate?.createListingResponse?(success: false, error: "Amazon DynamoDB Save Error: \(error)")
				}
				self.delegate?.createListingResponse?(success: true, error: nil)
			}
		})
	}

	func getNearbyListings(userId : String, lat : Double, lon : Double) {
		// TODO: Filter based on user's choice and location
		let scanExpression = AWSDynamoDBScanExpression()
		scanExpression.limit = 20
//		scanExpression.filterExpression = "Price < :val"
//		scanExpression.expressionAttributeValues = [":val": 50]
		dynamoDbObjectMapper.scan(Listing.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.getListingsResponse?(success: false, listings: [], error: error.localizedDescription)
				} else if let paginatedOutput = task.result {
					self.delegate?.getListingsResponse?(success: true, listings: paginatedOutput.items as! [Listing], error: nil)
				}
			}
			return nil
		})
	}
}

@objc protocol DBDelegate {
	@objc optional func createUserResponse(success : Bool, error : String?)
	@objc optional func createListingResponse(success : Bool, error : String?)
	@objc optional func getListingsResponse(success : Bool, listings : [Listing], error : String?)
}
