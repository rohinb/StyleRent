//
//  Services.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/4/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import FBSDKLoginKit
class Services {
	var delegate : ServicesDelegate?
	private let PAGE_AMOUNT = 6
	private let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()

	private static var instance : Services?
	static func shared() -> Services {
		if let instance = instance {
			return instance
		} else {
			let newDB = Services()
			instance = newDB
			return newDB
		}
	}

	func fbLogin() {
		FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, email, name"]).start { (conn, result, err) in
			if err != nil {
				self.delegate?.fbLoginResponse?(success: false, id: nil, name: nil, email: nil)
			} else {
				let user = User()
				if let results = result as? [String : String] {
					self.delegate?.fbLoginResponse?(success: true, id: results["id"], name: results["email"], email: results["name"])
				} else {
					self.delegate?.fbLoginResponse?(success: false, id: nil, name: nil, email: nil)
				}
			}
		}
	}
}

@objc protocol ServicesDelegate {
	@objc optional func fbLoginResponse(success : Bool, id : String?, name : String?, email : String?)
}
