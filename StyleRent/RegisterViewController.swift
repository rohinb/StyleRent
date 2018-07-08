//
//  RegisterViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/7/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import SendBirdSDK

class RegisterViewController: UIViewController {

	@IBOutlet weak var idField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var confirmPasswordField: UITextField!
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

	@IBAction func manualRegister() {
		if passwordField.text == confirmPasswordField.text {
			DB.shared().createUser(id: idField.text!, authType: .manual, password: passwordField.text!)
		} else {
			singleActionPopup(title: "Entered passwords do not match.", message: nil)
		}
	}

	func attemptFbLogin() {
		if FBSDKAccessToken.current() != nil {
			Services.shared().fbLogin()
		}
	}
}

extension RegisterViewController : DBDelegate {
	func createUserResponse(success: Bool, user: User?, error: String?) {
		if success {
			gblUser = user!
			self.performSegue(withIdentifier: "registerSegue", sender: nil)
		} else {
			popupAlert(title: "Failed to register user", message: error, actionTitles: ["Ok"], actions: [nil])
		}
	}
}

extension RegisterViewController : ServicesDelegate {
	func fbLoginResponse(success: Bool, id: String?, name: String?, email: String?) {
		if success {
			// TODO: Handle image
			let profileImageUrl = "http://graph.facebook.com/\(String(describing: id))/picture?type=square"
			// TODO: Move Send Bird connection into Services class with delegate response callback
			SBDMain.connect(withUserId: email!, completionHandler: { (newUser, error) in
				SBDMain.updateCurrentUserInfo(withNickname: name!, profileUrl: profileImageUrl, completionHandler: { (error) in
					print("Connected to SendBird and set up user")
				})
			})
			DB.shared().createUser(id: email!, authType: .facebook, password: nil)
		} else {
			self.popupAlert(title: "Failed to register through Facebook", message: "Would you like to try again?", actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
				self.attemptFbLogin()
				}, nil])
		}
	}
}


