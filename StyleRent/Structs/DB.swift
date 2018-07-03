//
//  File.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import AWSDynamoDB
import MapKit

/**
	Singleton class for calling DB methods. Delegate methods should always be called in Main Thread.
*/

class DB {
	var delegate : DBDelegate?
	private let PAGE_AMOUNT = 6
	private let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()

	private static var instance : DB?
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

	func getNearbyListings(userId : String, lat : Double, lon : Double, radius : Double, minPrice : Double?, maxPrice : Double?, category : String?, size : String?, showMyListings: Bool, lastEvalKey : [String : AWSDynamoDBAttributeValue]?) {
		let boundingRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: lat, longitude: lon), radius, radius)
		let latDelta = boundingRegion.span.latitudeDelta
		let lonDelta = boundingRegion.span.longitudeDelta

		let latStart = lat - latDelta
		let	latEnd = lat + latDelta
		let	lonStart = lon - lonDelta
		let	lonEnd = lon + lonDelta

		let expression = AWSDynamoDBScanExpression()
		expression.limit = PAGE_AMOUNT as NSNumber
		expression.exclusiveStartKey = lastEvalKey

		var filterExpression = "latitude BETWEEN :latStart AND :latEnd AND longitude BETWEEN :lonStart AND :lonEnd AND price BETWEEN :minPrice AND :maxPrice"
		var attrValues = [String : Any]()
		attrValues[":latStart"] = latStart
		attrValues[":latEnd"] = latEnd
		attrValues[":lonStart"] = lonStart
		attrValues[":lonEnd"] = lonEnd
		attrValues[":maxPrice"] = maxPrice ?? 99999
		attrValues[":minPrice"] = minPrice ?? 0
		if category != nil {
			filterExpression += " AND category = :category"
			attrValues[":category"] = category
		}

		if size != nil {
			filterExpression += " AND size = :size"
			attrValues[":size"] = size
		}

		if showMyListings {
			filterExpression += " AND sellerId = :sellerId"
			attrValues[":sellerId"] = userId
		} else {
			filterExpression += " AND sellerId <> :sellerId" // only show other users' listings
			attrValues[":sellerId"] = userId
		}

		expression.filterExpression = filterExpression

		expression.expressionAttributeValues = attrValues

//		scanExpression.filterExpression = "Price < :val"
//		scanExpression.expressionAttributeValues = [":val": 50]
		dynamoDbObjectMapper.scan(Listing.self, expression: expression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.getListingsResponse?(success: false, listings: [], error: error.localizedDescription, lastEval: nil)
				} else if let paginatedOutput = task.result {
					self.delegate?.getListingsResponse?(success: true, listings: paginatedOutput.items as! [Listing], error: nil, lastEval: paginatedOutput.lastEvaluatedKey)
				}
			}
			return nil
		})
	}

	func deleteListing(_ listing : Listing) {
		dynamoDbObjectMapper.remove(listing).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as? NSError {
					print("The request failed. Error: \(error)")
					self.delegate?.deleteListingResponse?(success: false)
				} else {
					self.delegate?.deleteListingResponse?(success: true)
				}
			}
		})
		// TODO: Delete images associated with listing
	}
}

@objc protocol DBDelegate {
	@objc optional func createUserResponse(success : Bool, error : String?)
	@objc optional func createListingResponse(success : Bool, error : String?)
	@objc optional func getListingsResponse(success : Bool, listings : [Listing], error : String?, lastEval : [String : AWSDynamoDBAttributeValue]?)
	@objc optional func deleteListingResponse(success : Bool)
}
