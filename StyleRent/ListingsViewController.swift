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
import AWSDynamoDB
import ESPullToRefresh

class ListingsViewController: UIViewController {
	@IBOutlet weak var collectionView: UICollectionView!

	fileprivate var locManager = CLLocationManager()
	fileprivate var currentLocation: CLLocation!
	fileprivate var listings = [Listing]()
	fileprivate var listingImages = [String : UIImage]()
	fileprivate var freshPull = true
	fileprivate var currentFilter = ListingDetail()
	fileprivate var lastEvalKey : [String : AWSDynamoDBAttributeValue]?

	var listingsOwnerName : String?
	var listingsOwnerId : String?
	var onlyMyListings = false

	fileprivate let reuseIdentifier = "ListingCell"
	static let kCellHeight = 200.0

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
		collectionView.addInfiniteScroll { (collectionView) in
			self.fetchListings()
		}

		collectionView.setShouldShowInfiniteScrollHandler { _ -> Bool in
			return self.freshPull || self.lastEvalKey != nil
		}
		collectionView.infiniteScrollTriggerOffset = 100.0 // TODO: Fine tune
		collectionView.beginInfiniteScroll(true)

		self.collectionView.es.addPullToRefresh {
			[unowned self] in
			self.performFreshPull()
		}

		title = onlyMyListings ? "\(listingsOwnerName!)'s Closet" : "Listings"

    }

	fileprivate func performFreshPull() {
		freshPull = true
		lastEvalKey = nil
		listings = []
		listingImages = [:]
		collectionView.reloadData()
		fetchListings()
	}

	fileprivate func fetchListings() {
		DB.shared().getNearbyListings(userId: onlyMyListings ? listingsOwnerId! : gblUserId, lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude, radius: 1000, minPrice: nil, maxPrice: nil, category: currentFilter.category?.rawValue, size: currentFilter.size, showMyListings: onlyMyListings, lastEvalKey: self.lastEvalKey)
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
					if data == nil { return } // handle weird edge case
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

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let index = sender as? Int, let dest = segue.destination as? ListingDetailsViewController {
			dest.listing = listings[index]
		}

		if segue.identifier == "toFilter" {
			let dest = segue.destination as! UINavigationController
			let vc = dest.viewControllers[0] as! FiltersViewController
			vc.currentDetail = currentFilter
			vc.delegate = self
		}
	}

	@IBAction func filterPressed(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "toFilter", sender: nil)
	}
}

extension ListingsViewController : DBDelegate {
	func getListingsResponse(success: Bool, listings: [Listing], error: String?, lastEval: [String : AWSDynamoDBAttributeValue]?) {
		print(success, listings)
		let initialCount = self.listings.count
		self.listings += listings
		lastEvalKey = lastEval
		freshPull = false
		let newIndexes = initialCount..<(listings.count + initialCount)
		for index in newIndexes { // load only new images
			loadImage(index: index)
		}
		let indexPathsToReload = newIndexes.map { (index) -> IndexPath in
			return IndexPath(item: index, section: 0)
		}
		collectionView.insertItems(at: indexPathsToReload)
		collectionView.finishInfiniteScroll()
		collectionView.es.stopPullToRefresh()
	}
}

extension ListingsViewController : FiltersDelegate {
	func filtersUpdated(newDetail: ListingDetail) {
		self.currentFilter = newDetail
		performFreshPull()
	}
}

// MARK: UICollectionView
extension ListingsViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return listings.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListingCell
		let listing = listings[indexPath.row]
		cell.listingNameLabel.text = listing._name!
		cell.sizeLabel.text = "Size: \(listing._size!)"
		cell.lenderNameLabel.text = "By \(listing._sellerId!)"
		cell.priceLabel.text = "$\(listing._price!)"
		cell.listingImageView.image = listingImages[listing._id!] ?? nil
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		performSegue(withIdentifier: "toListingDetails", sender: indexPath.row)
	}

	//make sure that it's two columns of cells
	func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.size.width / 2 - 16, height: CGFloat(ListingsViewController.kCellHeight))
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize(width: self.view.frame.width, height: 24)
	}
}



