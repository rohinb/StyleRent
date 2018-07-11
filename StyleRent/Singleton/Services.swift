//
//  Services.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/4/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import AWSDynamoDB
import AWSS3
import SendBirdSDK

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
				if let results = result as? [String : String] {
					self.delegate?.fbLoginResponse?(success: true, id: results["id"], name: results["name"], email: results["email"])
				} else {
					self.delegate?.fbLoginResponse?(success: false, id: nil, name: nil, email: nil)
				}
			}
		}
	}

	func uploadImageToS3(image : UIImage, key : String) {
		let data = UIImageJPEGRepresentation(image, 0.7)!

		let expression = AWSS3TransferUtilityUploadExpression()
		expression.progressBlock = nil

		var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
		completionHandler = { (task, error) -> Void in
			DispatchQueue.main.async(execute: {
				if error != nil {
					self.delegate?.uploadImageResponse?(success: false)
				} else {
					self.delegate?.uploadImageResponse?(success: true)
				}
			})
		}

		let transferUtility = AWSS3TransferUtility.default()

		transferUtility.uploadData(data,
								   key: key,
			contentType: "image/jpg",
			expression: expression,
			completionHandler: completionHandler).continueWith {
				(task) -> AnyObject? in
				return nil
		}
	}

	func connectSendBird(user : User, imageUrlString : String) {
		SBDMain.connect(withUserId: user._id!, completionHandler: { (newUser, error) in
			SBDMain.updateCurrentUserInfo(withNickname: user._name!, profileUrl: imageUrlString, completionHandler: { (error) in
				self.delegate?.connectSendBirdResponse?(success: error == nil)
			})
		})
	}
}

@objc protocol ServicesDelegate {
	@objc optional func fbLoginResponse(success : Bool, id : String?, name : String?, email : String?)
	@objc optional func uploadImageResponse(success : Bool)
	@objc optional func connectSendBirdResponse(success : Bool)
}
