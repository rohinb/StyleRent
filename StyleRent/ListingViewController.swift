//
//  ListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import MapKit
import AWSS3

class ListingViewController: UIViewController {
	var locManager = CLLocationManager()
	var currentLocation: CLLocation!
	var listings = [Listing]()
	var listingImages = [String : UIImage]()
	@IBOutlet weak var tableView: UITableView!

	override func viewDidLoad() {
        super.viewDidLoad()
		DB.delegate = self
		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(UINib(nibName: "ListingCell", bundle: nil), forCellReuseIdentifier: "listingCell")
		locManager.requestWhenInUseAuthorization()


		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
			CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
			currentLocation = locManager.location
			print(currentLocation.coordinate.latitude)
			print(currentLocation.coordinate.longitude)
			let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude), 1000, 1000)
			print(region)
		}
    }

	fileprivate func loadImage(index : Int) {
		let listing = listings[index]
		let fileName = "listing-images/\(listing._id!)-\(index + 1)"
		let expression = AWSS3TransferUtilityDownloadExpression()
		expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
			print(progress.fractionCompleted)
		})
		}

		var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
		completionHandler = { (task, URL, data, error) -> Void in
			DispatchQueue.main.async(execute: {
				if error != nil {
					print(error)
				} else {
					print("downlaod complete")
					self.listingImages[listing._id!] = UIImage(data: data!)
					self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
				}
			})
		}

		let transferUtility = AWSS3TransferUtility.default()

		transferUtility.downloadData(
			forKey: fileName,
			expression: expression,
			completionHandler: completionHandler
			).continueWith {
				(task) -> AnyObject? in if let error = task.error {
					print("Error: \(error.localizedDescription)")
				}

				if let _ = task.result {
					// Do something with downloadTask.
					print(task.result)

				}
				return nil;
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		DB.delegate = self
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
		self.listings = listings
		for index in 0..<listings.count {
			loadImage(index: index)
		}
		tableView.reloadData()
	}
}

extension ListingViewController : UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return listings.count
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 80
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "listingCell") as! ListingCell
		let listing = listings[indexPath.row]
		cell.listingName.text = listing._id!
		cell.listingImageView.image = listingImages[listing._id!] ?? #imageLiteral(resourceName: "loadingImage")
		return cell
	}
}



