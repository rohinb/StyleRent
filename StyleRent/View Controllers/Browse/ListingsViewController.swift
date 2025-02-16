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

enum ListingsVCConfig {
	case browse
	case closet
	case rentals
}

class ListingsViewController: UIViewController {
	@IBOutlet weak var collectionView: UICollectionView!

	fileprivate let reuseIdentifier = "ListingCell"
	static let kCellHeight = 200.0

	fileprivate var hadLocationImmediately = false
	fileprivate var listings = [Listing]()
	fileprivate var listingImages = [String : UIImage]()
	fileprivate var freshPull = true
	fileprivate var currentFilter = ListingDetail()
	fileprivate var lastEvalKey : [String : AWSDynamoDBAttributeValue]?
	fileprivate var numListingCallbacksReceived = 0
	fileprivate var listingsById = [String : Listing]()

	var config = ListingsVCConfig.browse
	// if rental
	var rentals : [Rental]?
	var iAmLender = false
	var listingIds : [String]?
	// if closet
	var listingsOwnerName : String?
	var listingsOwnerId : String?

	override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self

		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.register(UINib(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		collectionView.backgroundColor = UIColor.clear
		gblLocManager.delegate = self
		gblLocManager.requestWhenInUseAuthorization()

		if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
			CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) {
			if let loc = gblLocManager.location {
				gblCurrentLocation = loc
				hadLocationImmediately = true
			} else {
				gblLocManager.startUpdatingLocation()
			}
		}

		if config != .rentals {
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
		} else {
			self.performFreshPull()
		}

		title = getTitle()

		gblUser._pushEndpoint = Defaults.standard.string(forKey: Defaults.pushEndpointKey)
		DB.shared().updateUser(gblUser)
    }

	fileprivate func getTitle() -> String {
		switch config {
		case .browse: return "Listings"
		case .closet: return (listingsOwnerId! == gblUser._id! ? "My Closet" : "\(listingsOwnerName!)'s Closet")
		case .rentals: return iAmLender ? "Currently Rented Out" : "My Current Rentals"
		}
	}

	@objc fileprivate func settingsButtonPressed() {
		self.performSegue(withIdentifier: "listingsToSettings", sender: nil)
	}

	fileprivate func performFreshPull() {
		freshPull = true
		lastEvalKey = nil
		listings = []
		listingImages = [:]
		collectionView.reloadData()
		fetchListings()
	}

	fileprivate func fetchListings(count: Int = DB.PAGE_AMOUNT) {
		guard count > 0 else { return }
		if config != .rentals {
			if gblCurrentLocation != nil {
				DB.shared().getListings(userId: config == .closet ? listingsOwnerId! : gblUser._id!, lat: gblCurrentLocation.coordinate.latitude, lon: gblCurrentLocation.coordinate.longitude, radius: currentFilter.distanceRadius * 1609, minPrice: nil, maxPrice: nil, category: currentFilter.category?.rawValue, size: currentFilter.size, showMyListings: config == .closet, lastEvalKey: self.lastEvalKey, limit: count)
			} else {
				collectionView.finishInfiniteScroll()
				collectionView.es.stopPullToRefresh()
			}
		} else {
			for rental in rentals! {
				DB.shared().getListing(with: rental._listingId!)
			}
		}
	}

	fileprivate func loadImage(index : Int) {
		let listing = listings[index]
		let fileName = "listing-images/\(listing._id!)-1"
		let expression = AWSS3TransferUtilityDownloadExpression()
		expression.progressBlock = nil

		var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
		completionHandler = { (task, URL, data, error) -> Void in
			DispatchQueue.main.async(execute: {
				if error != nil {
					print(error!)
				} else {
					print("downlaod complete")
					if data == nil { return } // handle weird edge case
					self.listingImages[listing._id!] = UIImage(data: data!)
					if self.listings.count > index { // fix to prevent pending download from crashing after new filter was applied
						self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
					}
				}
			})
		}

		let transferUtility = AWSS3TransferUtility.default()

		transferUtility.downloadData(
			forKey: fileName,
			expression: expression,
			completionHandler: completionHandler
			).continueWith {
				(task) -> AnyObject? in
				return nil
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

	fileprivate func getDistanceString(for listing : Listing) -> String {
		if listingsOwnerId == gblUser._id {
			return "Less than a mile"
		}
		let lat = listing._latitude!.doubleValue
		let lon = listing._longitude!.doubleValue
		let metersAway = gblCurrentLocation.distance(from: CLLocation(latitude: lat, longitude: lon))
		let milesAway = Int(metersAway / 1609.344)
		let distanceString = milesAway < 1 ? "Less than a mile" : milesAway == 1 ? "1 mile" : "\(milesAway) miles"
		return distanceString
	}
}

extension ListingsViewController : DBDelegate {
	func getListingsResponse(success: Bool, listings: [Listing], error: String?, lastEval: [String : AWSDynamoDBAttributeValue]?) {
		print(success, listings)
		if success {
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
			// continue fetching if not enough have been found
			if lastEval != nil && (self.listings.count % DB.PAGE_AMOUNT != 0 || self.listings.count == 0) {
				let remaining = DB.PAGE_AMOUNT - (self.listings.count % DB.PAGE_AMOUNT)
				print("Continuing to fetch. Received: \(listings.count). Have: \(self.listings.count) Want \(remaining) more.")
				fetchListings(count: remaining)
			} else {
				print("done fetching")
				collectionView.finishInfiniteScroll()
				collectionView.es.stopPullToRefresh()
			}
		} else {
			collectionView.finishInfiniteScroll()
			collectionView.es.stopPullToRefresh()
			singleActionPopup(title: "Failed to fetch listings", message: "Please try again later.")
		}
	}

	func getListingResponse(success: Bool, listing: Listing?, error: String?) {
		numListingCallbacksReceived += 1
		if success {
			listingsById[listing!._id!] = listing!
		} else {
			singleActionPopup(title: "Failed to fetch all listings", message: "Please try again later.")
		}
		if numListingCallbacksReceived == rentals!.count {
			for (index, rental) in rentals!.enumerated() { // maintain order of sorted rentals
				listings.append(listingsById[rental._listingId!]!)
				loadImage(index: index)
			}
			collectionView.reloadData()
		}
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
		cell.lenderNameLabel.text = getDistanceString(for: listing) // showing distance here instead of lender name for now.
		cell.priceLabel.text = "$\(listing._price!)"
		cell.listingImageView.image = listingImages[listing._id!] ?? nil
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if config == .rentals {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewController(withIdentifier: "RentalVC") as! RentalViewController
			vc.config = .history
			vc.rental = rentals![indexPath.row]
			vc.listing = listings[indexPath.row]
			vc.isMyListing = iAmLender
			self.navigationController?.pushViewController(vc, animated: true)
		} else {
			performSegue(withIdentifier: "toListingDetails", sender: indexPath.row)
		}
	}

	//make sure that it's two columns of cells
	func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.size.width / 2 - 10, height: CGFloat(ListingsViewController.kCellHeight))
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 20
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize(width: self.view.frame.width, height: 24)
	}
}

extension ListingsViewController : CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedAlways || status == .authorizedWhenInUse {
			if !hadLocationImmediately {
				gblLocManager.startUpdatingLocation()
			}
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("updated locations")
		gblLocManager.stopUpdatingLocation() // i don't need anymore locations
		gblCurrentLocation = locations.last
		self.performFreshPull()
	}

}



