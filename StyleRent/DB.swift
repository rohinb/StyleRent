//
//  File.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import AWSDynamoDB

struct DB {
	private static let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
	static var delegate : DBDelegate?

	static func createUser(user : User) {
		
		dynamoDbObjectMapper.save(user, completionHandler: {
			(error: Error?) -> Void in

			if let error = error {
				delegate?.createUserResponse(success: false, error: "Amazon DynamoDB Save Error: \(error)")
			}
			delegate?.createUserResponse(success: true, error: nil)
		})
	}
}

protocol DBDelegate {
	func createUserResponse(success : Bool, error : String?)
}
