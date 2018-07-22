//
//  RentRootViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/20/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import SVProgressHUD

class RentRootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		DB.shared().delegate = self
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func viewMyRentals(_ sender: Any) {
		SVProgressHUD.show(withStatus: "Fetching your rentals...")
		DB.shared().getRentals(userId: gblUser._id!, lended: false)
	}

	@IBAction func viewMyRentedOut(_ sender: Any) {
		SVProgressHUD.show(withStatus: "Fetching your rented out items...")
		DB.shared().getRentals(userId: gblUser._id!, lended: true)
	}

}

extension RentRootViewController : DBDelegate {
	func getRentalsResponse(success: Bool, rentals: [Rental], lended: Bool, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewController(withIdentifier: "ListingsVC") as! ListingsViewController
			vc.rentals = rentals
			vc.config = .rentals
			vc.iAmLender = lended
			vc.listingIds = rentals.map({ (rental) -> String in return rental._listingId! })
			navigationController?.pushViewController(vc, animated: true)
			print(rentals)
		} else {
			singleActionPopup(title: "Failed to fetch rentals.", message: "Please try again.")
		}
	}
}
