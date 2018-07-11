//
//  ViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSAuthCore
import FBSDKLoginKit
import SendBirdSDK
import SVProgressHUD

class LoginViewController: UIViewController {
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var idField: UITextField!

	var firstTime = true

	override func viewDidLoad() {
		super.viewDidLoad()
		API.doInvokeAPI()
		DB.shared().delegate = self
		Services.shared().delegate = self

		let loginButton = FBSDKLoginButton()
		loginButton.readPermissions = ["email"]
		loginButton.center = self.view.center
		self.view.addSubview(loginButton)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if !firstTime {
			attemptFbLogin()
		}
		firstTime = false
	}

	@IBAction func manualLogin() {
		SVProgressHUD.show(withStatus: "Logging in...")
		DB.shared().validateUser(id: idField.text!, authType: .manual, password: passwordField.text!)
	}

	fileprivate func attemptFbLogin() {
		if FBSDKAccessToken.current() != nil {
			SVProgressHUD.show(withStatus: "Logging in...")
			Services.shared().fbLogin()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension LoginViewController : DBDelegate {
	func validateUserResponse(success: Bool, user : User?, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			gblUser = user!
			self.performSegue(withIdentifier: "loginSegue", sender: nil)
		} else {
			// login did not go through, so log out of services
			FBSDKAccessToken.setCurrent(nil)
			FBSDKLoginManager().logOut()
			singleActionPopup(title: error, message: nil)
		}
	}
}

extension LoginViewController : ServicesDelegate {
	func fbLoginResponse(success: Bool, id: String?, name: String?, email: String?) {
		if success {
			DB.shared().validateUser(id: email!, authType: AuthType.facebook, password: nil)
		} else {
			SVProgressHUD.dismiss()
			self.popupAlert(title: "Failed to login through Facebook", message: "Would you like to try again?", actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
				self.attemptFbLogin()
				}, nil])
		}
	}
}

