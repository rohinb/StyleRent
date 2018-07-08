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

struct API {
	static func doInvokeAPI() {
		// change the method name, or path or the query string parameters here as desired
		let httpMethodName = "POST"
		// change to any valid path you configured in the API
		let URLString = "/handoff"
		let queryStringParameters = ["key1":"{value1}"]
		let headerParameters = [
			"Content-Type": "application/json",
			"Accept": "application/json"
		]

		let httpBody = "{ \n  " +
			"\"key1\":\"value1\", \n  " +
			"\"key2\":\"value2\", \n  " +
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
				// Handle error here
				return nil
			}

			// Handle successful result here
			let result = task.result!
			let responseString =
				String(data: result.responseData!, encoding: .utf8)

			let dict = responseString?.toJSON() as? [String:AnyObject]

			print(dict)
			print(result.statusCode)

			return nil
		}
	}
}
