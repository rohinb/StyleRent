//
//  ConfirmViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import Nuke
import SVProgressHUD

enum RentalViewControllerConfig {
	case confirmPickup
	case confirmDropoff
	case history
}

class RentalViewController: UIViewController {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var listingImageView: UIImageView!
	@IBOutlet weak var listingNameLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var acceptButton: UIButton!
	@IBOutlet weak var rejectButton: UIButton!
	@IBOutlet weak var handoffButton: UIButton!

	var listing : Listing!
	var config = RentalViewControllerConfig.confirmPickup

	//history config vars
	var rental : Rental!
	var isMyListing : Bool!
	var lender : User!
	var borrower : User!

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self
		Nuke.loadImage(
			with: Utilities.getUrlForListingPicture(listingId: listing?._id ?? rental._listingId!, imageNumber: 1),
			options: ImageLoadingOptions(
				placeholder: #imageLiteral(resourceName: "placeholder"),
				transition: .fadeIn(duration: 0.33)
			),
			into: listingImageView
		)
		handoffButton.isHidden = config != .history

		switch config {
		case .confirmPickup:
			priceLabel.text = "Rental price: \(listing._price!.intValue)"
		case .confirmDropoff:
			titleLabel.text = "Confirm return"
			priceLabel.text = "Hit Accept to take back the item and end the rental. You will receive the payment and be able to report any damages in the next 24 hours."
		case .history:
			listingNameLabel.text = listing._name!
			fetchTransactors()
			acceptButton.isHidden = true
			rejectButton.isHidden = true
			titleLabel.isHidden = true
			priceLabel.text = "Rental price: \(rental._price!.intValue)"
			handoffButton.setTitle(isMyListing ? "Receive" : "Return", for: UIControlState())
		}
    }

	@IBAction func initiateHandoff(_ sender: Any) {
		if isMyListing {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewController(withIdentifier: "ScanningVC") as! QRScannerController
			self.present(vc, animated: true, completion: nil)
		} else {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewController(withIdentifier: "HandoffVC") as! HandoffViewController
			vc.config = .dropoff
			vc.rental = rental
			self.present(vc, animated: true, completion: nil)
		}
	}

	fileprivate func renderUser() {
		if isMyListing {
			titleLabel.text = "\(borrower._name!) rented from you on \(rental._startDate!)"
		} else {
			titleLabel.text = "You rented from \(lender._name!) on \(rental._startDate!)"
		}
	}

	fileprivate func fetchTransactors() {
		SVProgressHUD.show(withStatus: "Fetching rental information...")
		if !isMyListing {
			DB.shared().getUser(with: rental._lenderId!)
		} else {
			DB.shared().getUser(with: rental._borrowerId!)
		}
	}

	@IBAction func acceptPressed(_ sender: Any) {
		if config == .confirmPickup {
			let checkoutViewController = CheckoutViewController(listing: listing,
																price: listing._price!.intValue * 100)
			checkoutViewController.confirmVc = self
			self.present(checkoutViewController, animated: true, completion: nil)
		} else {
			// finalize return and notify other user to give back item
			SVProgressHUD.show(withStatus: "Finishing rental...")
			rental._isActive = false
			DB.shared().createRental(rental: rental)
		}
	}

	@IBAction func rejectPressed(_ sender: Any) {
		// TODO: notify seller of rejection? -- nahhhhh
		self.dismiss(animated: true, completion: nil)
	}

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RentalViewController : DBDelegate {
	func getUserResponse(success: Bool, user: User?, error: String?) {
		if success {
			if user!._id! == rental._borrowerId {
				borrower = user!
			} else {
				lender = user!
			}
			renderUser()
		} else {
			singleActionPopup(title: "Failed to fetch other user's information", message: nil, action: nil)
		}
	}

	func createRentalResponse(success: Bool, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			singleActionPopup(title: "Rental has been finished!", message: "Instruct the borrower to return the listing item to you now and the return is complete.") { (action) in
				self.dismiss(animated: true, completion: nil)
			}
		} else {

		}
	}
}
