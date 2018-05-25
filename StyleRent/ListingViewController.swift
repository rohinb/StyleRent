//
//  ListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import MapKit

class ListingViewController: UIViewController {
	var locManager = CLLocationManager()
	var currentLocation: CLLocation!


    override func viewDidLoad() {
        super.viewDidLoad()
		DB.delegate = self
		locManager.requestWhenInUseAuthorization()

		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
			CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
			currentLocation = locManager.location
			print(currentLocation.coordinate.latitude)
			print(currentLocation.coordinate.longitude)
		}
        DB.getNearbyListings(userId: gblUserId, lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ListingViewController : DBDelegate {
	func getListingsResponse(success: Bool, listings: [Listing], error: String?) {
		print(success, listings)
	}
}
