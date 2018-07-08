//
//  Utilities.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/8/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation

struct Utilities {
	static func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		URLSession.shared.dataTask(with: url) { data, response, error in
			completion(data, response, error)
			}.resume()
	}
}
