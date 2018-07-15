//
//  ConfirmViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import Nuke

class ConfirmViewController: UIViewController {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var listingImageView: UIImageView!
	@IBOutlet weak var listingNameLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!

	var listing : Listing!

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
    }

	@IBAction func acceptPressed(_ sender: Any) {
		// TODO: Trigger payment through stripe sdk
		// then create rental in DB. - DONE
		// Create trigger in Dynamo to call a lambda every time a rental is created
		// The lambda should notify both users of payment success
		let checkoutViewController = CheckoutViewController(listing: listing,
															price: listing._price!.intValue * 100)
		checkoutViewController.confirmVc = self
		self.present(checkoutViewController, animated: true, completion: nil)
	}

	@IBAction func rejectPressed(_ sender: Any) {
		// TODO: notify seller of rejection?
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
