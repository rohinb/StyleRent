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

	func updateUser(_ user : User) {
		dynamoDbObjectMapper.save(user, completionHandler: {
			(error: Error?) -> Void in

			DispatchQueue.main.async {
				if let error = error {
					self.delegate?.updateUserResponse?(success: false, error: "Amazon DynamoDB Save Error: \(error)")
				}
				self.delegate?.updateUserResponse?(success: true, error: nil)
			}
		})
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
						user._pushEndpoint = Defaults.standard.string(forKey: Defaults.pushEndpointKey)
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

	func createConversation(convo : Conversation) {

		dynamoDbObjectMapper.save(convo, completionHandler: {
			(error: Error?) -> Void in
			DispatchQueue.main.async {
				if let error = error {
					self.delegate?.createConversationResponse?(success: false, error: "Amazon DynamoDB Save Error: \(error)")
				}
				self.delegate?.createConversationResponse?(success: true, error: nil)
			}
		})
	}

	func createRental(rental : Rental) {

		dynamoDbObjectMapper.save(rental, completionHandler: {
			(error: Error?) -> Void in

			DispatchQueue.main.async {
				if let error = error {
					self.delegate?.createRentalResponse?(success: false, error: "Amazon DynamoDB Save Error: \(error)")
				}
				self.delegate?.createRentalResponse?(success: true, error: nil)
			}
		})
	}

	func getListings(userId : String, lat : Double, lon : Double, radius : Double, minPrice : Double?, maxPrice : Double?, category : String?, size : String?, showMyListings: Bool, lastEvalKey : [String : AWSDynamoDBAttributeValue]?, limit : Int) {
		let boundingRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: lat, longitude: lon), radius, radius)
		let latDelta = boundingRegion.span.latitudeDelta
		let lonDelta = boundingRegion.span.longitudeDelta

		let latStart = lat - latDelta
		let	latEnd = lat + latDelta
		let	lonStart = lon - lonDelta
		let	lonEnd = lon + lonDelta

		for blockId in Utilities.getBlockIdsInRange(startLat: latStart, endLat: latEnd, startLong: lonStart, endLong: lonEnd) {
			print("fetching block id: " + blockId)
			let expression = AWSDynamoDBQueryExpression()
			var attrValues = [String : Any]()
			var filterExpressions = [String]()
			attrValues[":userId"] = userId

			if showMyListings {
				expression.indexName = "sellerId-index"
				expression.keyConditionExpression = "sellerId = :userId"
			} else {
				expression.indexName = "blockId-longitude-index"
				expression.keyConditionExpression = "blockId = :blockId AND longitude BETWEEN :lonStart AND :lonEnd"
				attrValues[":latStart"] = latStart
				attrValues[":latEnd"] = latEnd
				attrValues[":lonStart"] = lonStart
				attrValues[":lonEnd"] = lonEnd
				attrValues[":blockId"] = blockId

				filterExpressions.append("latitude BETWEEN :latStart AND :latEnd")
				filterExpressions.append("sellerId <> :userId") // only show other users' listings
			}

			expression.limit = limit as NSNumber
			expression.exclusiveStartKey = lastEvalKey

			if minPrice != nil {
				filterExpressions.append("price BETWEEN :minPrice AND :maxPrice")
				attrValues[":maxPrice"] = maxPrice ?? 99999
				attrValues[":minPrice"] = minPrice ?? 0
			}
			if category != nil {
				filterExpressions.append("category = :category")
				attrValues[":category"] = category
			}

			if size != nil {
				filterExpressions.append("size = :size")
				attrValues[":size"] = size
			}

			// connect each clause with an 'AND'
			if !filterExpressions.isEmpty {
				var filterExpression = filterExpressions[0]
				for i in 1..<filterExpressions.count {
					let clause = filterExpressions[i]
					filterExpression += " AND " + clause
				}
				expression.filterExpression = filterExpression
			}

			expression.expressionAttributeValues = attrValues

			dynamoDbObjectMapper.query(Listing.self, expression: expression)
				.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
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

		dynamoDbObjectMapper.query(User.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
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

	func getListing(with id : String) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "id = :id"
		queryExpression.expressionAttributeValues = [":id" : id]

		dynamoDbObjectMapper.query(Listing.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.getListingResponse?(success: false, listing: nil, error: "Failed to connect to the server.")
				} else if let result = task.result {
					if let listing = result.items.first as? Listing {
						self.delegate?.getListingResponse?(success: true, listing: listing, error: nil)
					} else {
						self.delegate?.getListingResponse?(success: false, listing: nil, error: "Listing with id not found.")
					}
				}
			}
			return nil
		})
	}

	func getRental(with id : String) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "id = :id"
		queryExpression.expressionAttributeValues = [":id" : id]

		dynamoDbObjectMapper.query(Rental.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
				DispatchQueue.main.async {
					if let error = task.error as NSError? {
						print("The request failed. Error: \(error)")
						self.delegate?.getRentalResponse?(success: false, rental: nil, error: "Failed to connect to the server.")
					} else if let result = task.result {
						if let rental = result.items.first as? Rental {
							self.delegate?.getRentalResponse?(success: true, rental: rental, error: nil)
						} else {
							self.delegate?.getRentalResponse?(success: false, rental: nil, error: "Rental with id not found.")
						}
					}
				}
				return nil
			})
	}

	// gets the active rental, if there is one, for a given listing
	func getRentalForListing(withId listingId : String) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.indexName = "listingId-index"
		queryExpression.keyConditionExpression = "listingId = :listingId"
		queryExpression.filterExpression = "isActive = :isActive"
		queryExpression.expressionAttributeValues = [":listingId" : listingId, ":isActive" : true]

		dynamoDbObjectMapper.query(Rental.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
				DispatchQueue.main.async {
					if let error = task.error as NSError? {
						print("The request failed. Error: \(error)")
						self.delegate?.getRentalForListingResponse?(success: false, rental: nil, error: "Failed to connect to the server.")
					} else if let result = task.result {
						if let rental = result.items.first as? Rental {
							self.delegate?.getRentalForListingResponse?(success: true, rental: rental, error: nil)
						} else {
							self.delegate?.getRentalForListingResponse?(success: true, rental: nil, error: "Rental with id not found.")
						}
					}
				}
				return nil
			})
	}

	func getRentals(userId : String, lended : Bool, active : Bool = true) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.indexName = lended ? "lenderId-returnDate-index" : "borrowerId-returnDate-index"
		queryExpression.keyConditionExpression = "#key = :id"
		queryExpression.scanIndexForward = true
		queryExpression.filterExpression = "isActive = :active"
		queryExpression.expressionAttributeNames = ["#key" : lended ? "lenderId" : "borrowerId"]
		queryExpression.expressionAttributeValues = [":id" : userId, ":active" : active]


		dynamoDbObjectMapper.query(Rental.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
			DispatchQueue.main.async {
				if let error = task.error as NSError? {
					print("The request failed. Error: \(error)")
					self.delegate?.getRentalsResponse?(success: false, rentals: [], lended: lended, error: "Failed to fetch rentals.")
				} else if let result = task.result {
					self.delegate?.getRentalsResponse?(success: true, rentals: result.items as! [Rental], lended: lended, error: nil)
				}
			}
			return nil
		})
	}

	func getConversation(withUrl url : String) {
		let queryExpression = AWSDynamoDBQueryExpression()

		queryExpression.keyConditionExpression = "channelUrl = :id"
		queryExpression.expressionAttributeValues = [":id" : url]

		dynamoDbObjectMapper.query(Conversation.self, expression: queryExpression)
			.continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
				DispatchQueue.main.async {
					if let error = task.error as NSError? {
						print("The request failed. Error: \(error)")
						self.delegate?.getConversationResponse?(success: false, conversation: nil, error: "Failed to connect to the server.")
					} else if let result = task.result {
						if let conversation = result.items.first as? Conversation {
							self.delegate?.getConversationResponse?(success: true, conversation: conversation, error: nil)
						} else {
							self.delegate?.getConversationResponse?(success: false, conversation: nil, error: "Conversation with url not found.")
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
	@objc optional func updateUserResponse(success : Bool, error : String?)
	@objc optional func createRentalResponse(success : Bool, error : String?)
	@objc optional func createConversationResponse(success : Bool, error : String?)
	@objc optional func getListingsResponse(success : Bool, listings : [Listing], error : String?, lastEval : [String : AWSDynamoDBAttributeValue]?)
	@objc optional func getRentalsResponse(success : Bool, rentals : [Rental], lended : Bool, error : String?)
	@objc optional func deleteListingResponse(success : Bool)
	@objc optional func validateUserResponse(success : Bool, user : User?, error : String?)
	@objc optional func getUserResponse(success : Bool, user : User?, error : String?)
	@objc optional func getListingResponse(success : Bool, listing : Listing?, error : String?)
	@objc optional func getRentalResponse(success : Bool, rental : Rental?, error : String?)
	@objc optional func getRentalForListingResponse(success : Bool, rental : Rental?, error : String?)
	@objc optional func getConversationResponse(success : Bool, conversation : Conversation?, error : String?)
}
