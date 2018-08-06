//
//  MyBalanceViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 8/5/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import SVProgressHUD
class MyBalanceViewController: UIViewController {
	@IBOutlet weak var balanceLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self
		SVProgressHUD.show(withStatus: "Fetching your balance...")
		DB.shared().getUser(with: gblUser._id!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MyBalanceViewController : DBDelegate {
	func getUserResponse(success: Bool, user: User?, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			gblUser = user!
			balanceLabel.text = "Your balance: $\(user!._balance!.intValue)"
		} else {
			singleActionPopup(title: "Failed to fetch your balance.", message: "Please try again later") { (action) in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
}
