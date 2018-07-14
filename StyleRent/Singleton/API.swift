//
//  APICalls.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/27/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import AWSAuthCore
import AWSCore
import AWSMobileClient
import AWSAPIGateway
import Stripe

//for lamdas

@objc protocol APIDelegate {
	@objc optional func getStripeEphemeralKeyResponse(success : Bool, key : String?)
}

class API {
	static let shared = API()
	var delegate : APIDelegate?

	fileprivate let stripeApiVersion = "2018-02-06"

	func getStripeEphemeralKey(for user: User) {
		// change the method name, or path or the query string parameters here as desired
		let httpMethodName = "POST"
		// change to any valid path you configured in the API
		let URLString = "/get-ephemeral-key"
		let queryStringParameters = ["customer_id":"\(user._stripeId!)", "api_version":"\(stripeApiVersion)"]
		let headerParameters = [
			"Content-Type": "application/json",
			"Accept": "application/json"
		]

		let httpBody = "{ \n  " +
			"\"customer_id\":\"value1\", \n  " +
			"\"api_version\":\"value2\", \n  " +
		"\"key3\":\"value3\"\n}"

		// Construct the request object
		let apiRequest = AWSAPIGatewayRequest(httpMethod: httpMethodName,
											  urlString: URLString,
											  queryParameters: queryStringParameters,
											  headerParameters: headerParameters,
											  httpBody: httpBody)

		// Create a service configuration object for the region your AWS API was created in
		let serviceConfiguration = AWSServiceConfiguration(
			region: AWSRegionType.USEast2,
			credentialsProvider: AWSMobileClient.sharedInstance().getCredentialsProvider())

		AWSAPI_DI8UQ5E635_StyleRentAPIMobileHubClient.register(with: serviceConfiguration!, forKey: "CloudLogicAPIKey")

		// Fetch the Cloud Logic client to be used for invocation
		let invocationClient =
			AWSAPI_DI8UQ5E635_StyleRentAPIMobileHubClient(forKey: "CloudLogicAPIKey")

		invocationClient.invoke(apiRequest).continueWith { (
			task: AWSTask) -> Any? in

			if let error = task.error {
				print("Error occurred: \(error)")
				self.delegate?.getStripeEphemeralKeyResponse?(success: false, key: nil)
				return nil
			}

			// Handle successful result here
			let result = task.result!
			let responseString =
				String(data: result.responseData!, encoding: .utf8)

			let dict = responseString?.toJSON() as! [String:AnyObject]

			print(dict)
			print(result.statusCode)
			if let err = dict["error"] as? String {
				print(err)
			} else {
				self.delegate?.getStripeEphemeralKeyResponse?(success: true, key: dict["ephemeral_key"] as? String)
			}

			return nil
		}
	}
}
