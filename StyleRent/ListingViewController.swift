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
	@IBOutlet weak var collectionView: UICollectionView!

	var locManager = CLLocationManager()
	var currentLocation: CLLocation!
	var listings = [Listing]()
	var listingImages = [String : UIImage]()

	let reuseIdentifier = "ListingCell"
	let kCellHeight = 200

	override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self

		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.register(UINib(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		collectionView.backgroundColor = UIColor.clear

		locManager.requestWhenInUseAuthorization()


		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
			CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
			currentLocation = locManager.location
			print(currentLocation.coordinate.latitude)
			print(currentLocation.coordinate.longitude)
			let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude), 1000, 1000)
			print(region)
		}

		DB.shared().getNearbyListings(userId: gblUserId, lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude)
    }

	fileprivate func loadImage(index : Int) {
		let listing = listings[index]
		let fileName = "listing-images/\(listing._id!)-1"
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
					self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
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
		DB.shared().delegate = self
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
		collectionView.reloadData()
	}
}

extension ListingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return listings.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListingCell
		let listing = listings[indexPath.row]
		cell.listingNameLabel.text = listing._id!
		cell.sizeLabel.text = "Size: \(listing._size!)"
		cell.lenderNameLabel.text = "By \(listing._sellerId!)"
		cell.priceLabel.text = "$\(listing._price!)"
		cell.listingImageView.image = listingImages[listing._id!] ?? nil
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		// TODO: Go to ListingDetailsViewController
	}

	//make sure that it's two columns of cells
	func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.size.width / 2 - 16, height: CGFloat(kCellHeight))
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize(width: self.view.frame.width, height: 24)
	}
}



