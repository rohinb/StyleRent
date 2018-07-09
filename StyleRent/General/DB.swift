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
	static let PAGE_AMOUNT = 6
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

	func createUser(id : String, name : String, authType : AuthType, password : String?) {
		// first check if user exists
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "id = :id"
		queryExpression.expressionAttributeValues = [":id" : id]

		dynamoDbObjectMapper.query(User.self, expression: queryExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.createUserResponse?(success: false, user: nil, error: "Failed to connect to the server.")
				} else if let result = task.result {
					if result.items.first != nil {
						// user already made, error
						self.delegate?.createUserResponse?(success: false, user : nil, error: "A user with this email address was previously registered")
					} else {
						// user not made yet, so create user
						let user = User()!
						user._id = id
						user._name = name
						user._authType = authType.rawValue
						user._password = password
						self.dynamoDbObjectMapper.save(user, completionHandler: { (error: Error?) -> Void in
							DispatchQueue.main.async {
								if error != nil {
									self.delegate?.createUserResponse?(success: false, user: nil, error: "Failed to connect to the server.")
								} else {
									self.delegate?.createUserResponse?(success: true, user: user, error: nil)
								}
							}
						})
					}
				}
			}
			return nil
		})
	}

	func validateUser(id : String, authType : AuthType, password : String?) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "id = :id"
		queryExpression.expressionAttributeValues = [":id" : id]

		dynamoDbObjectMapper.query(User.self, expression: queryExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.validateUserResponse?(success: false, user: nil, error: "Failed to connect to the server.")
				} else if let result = task.result {
					if let user = result.items.first as? User {
						if authType == .manual {
							if user._password == password {
								self.delegate?.validateUserResponse?(success: true, user : user, error: nil)
							} else {
								self.delegate?.validateUserResponse?(success: false, user : nil, error: "Incorrect password.")
							}
						} else {
							if user._authType == authType.rawValue {
								self.delegate?.validateUserResponse?(success: true, user: user, error: nil)
							} else {
								self.delegate?.validateUserResponse?(success: false, user : nil, error: "A user with this email address was previously registered with \(user._authType!)")
							}
						}
					} else {
						self.delegate?.validateUserResponse?(success: false, user : nil, error: "User with email address not found.")
					}
				}
			}
			return nil
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

	func getNearbyListings(userId : String, lat : Double, lon : Double, radius : Double, minPrice : Double?, maxPrice : Double?, category : String?, size : String?, showMyListings: Bool, lastEvalKey : [String : AWSDynamoDBAttributeValue]?, limit : Int) {
		let boundingRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: lat, longitude: lon), radius, radius)
		let latDelta = boundingRegion.span.latitudeDelta
		let lonDelta = boundingRegion.span.longitudeDelta

		let latStart = lat - latDelta
		let	latEnd = lat + latDelta
		let	lonStart = lon - lonDelta
		let	lonEnd = lon + lonDelta

		let expression = AWSDynamoDBScanExpression()
		expression.limit = limit as NSNumber
		expression.exclusiveStartKey = lastEvalKey

		var attrValues = [String : Any]()
		var filterExpression = "latitude BETWEEN :latStart AND :latEnd AND longitude BETWEEN :lonStart AND :lonEnd"
		attrValues[":latStart"] = latStart
		attrValues[":latEnd"] = latEnd
		attrValues[":lonStart"] = lonStart
		attrValues[":lonEnd"] = lonEnd

		if minPrice != nil {
			filterExpression += " AND price BETWEEN :minPrice AND :maxPrice"
			attrValues[":maxPrice"] = maxPrice ?? 99999
			attrValues[":minPrice"] = minPrice ?? 0
		}
		if category != nil {
			filterExpression += " AND category = :category"
			attrValues[":category"] = category
		}

		if size != nil {
			filterExpression += " AND size = :size"
			attrValues[":size"] = size
		}

		if showMyListings {
			filterExpression += " AND sellerId = :userId"
			attrValues[":userId"] = userId
		} else {
			filterExpression += " AND sellerId <> :userId" // only show other users' listings
			attrValues[":userId"] = userId
		}

		expression.filterExpression = filterExpression

		expression.expressionAttributeValues = attrValues

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
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.deleteListingResponse?(success: false)
				} else {
					self.delegate?.deleteListingResponse?(success: true)
				}
			}
		})
		// TODO: Delete images associated with listing
	}

	func getUser(with id : String) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "id = :id"
		queryExpression.expressionAttributeValues = [":id" : id]

		dynamoDbObjectMapper.query(User.self, expression: queryExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.getUserResponse?(success: false, user: nil, error: "Failed to connect to the server.")
				} else if let result = task.result {
					if let user = result.items.first as? User {
						self.delegate?.getUserResponse?(success: true, user: user, error: nil)
					} else {
						self.delegate?.getUserResponse?(success: false, user : nil, error: "User with email address not found.")
					}
				}
			}
			return nil
		})
	}
}

@objc protocol DBDelegate {
	@objc optional func createUserResponse(success : Bool, user : User?, error : String?)
	@objc optional func createListingResponse(success : Bool, error : String?)
	@objc optional func getListingsResponse(success : Bool, listings : [Listing], error : String?, lastEval : [String : AWSDynamoDBAttributeValue]?)
	@objc optional func deleteListingResponse(success : Bool)
	@objc optional func validateUserResponse(success : Bool, user : User?, error : String?)
	@objc optional func getUserResponse(success : Bool, user : User?, error : String?)
}