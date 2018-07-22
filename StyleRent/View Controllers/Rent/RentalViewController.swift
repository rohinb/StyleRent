//
//  ConfirmViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import Nuke

enum RentalViewControllerConfig {
	case confirm
	case history
}

class RentalViewController: UIViewController {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var listingImageView: UIImageView!
	@IBOutlet weak var listingNameLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var acceptButton: UIButton!
	@IBOutlet weak var rejectButton: UIButton!

	var listing : Listing!
	var config = RentalViewControllerConfig.confirm

	//history config vars
	var rental : Rental!
	var isMyListing : Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
		Nuke.loadImage(
			with: Utilities.getUrlForListingPicture(listingId: listing._id!, imageNumber: 1),
			options: ImageLoadingOptions(
				placeholder: #imageLiteral(resourceName: "placeholder"),
				transition: .fadeIn(duration: 0.33)
			),
			into: listingImageView
		)
		listingNameLabel.text = listing._name!

		if config == .confirm {
			// TODO: use listing object to populate UI
		} else if config == .history {
			acceptButton.isHidden = true
			rejectButton.isHidden = true
			titleLabel.isHidden = true
			// TODO: use rental object to populate UI
			// create a return/collect button based on isMyListing that takes them to give/receive page
		}
    }

	@IBAction func acceptPressed(_ sender: Any) {
		let checkoutViewController = CheckoutViewController(listing: listing,
															price: listing._price!.intValue * 100)
		checkoutViewController.confirmVc = self
		self.present(checkoutViewController, animated: true, completion: nil)
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
