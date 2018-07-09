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
import SVProgressHUD

class RegisterViewController: UIViewController {

	@IBOutlet weak var nameField: UITextField!
	@IBOutlet weak var idField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var confirmPasswordField: UITextField!
	var firstTime = true
	var profileImageUrl : String?

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
			attemptFbRegistration()
		}
		firstTime = false
	}

	fileprivate func isValidEntry() -> Bool {
		if isValidEmail(testStr: idField.text!) {
			if passwordField.text == confirmPasswordField.text {
				if isValidPassword(passwordField.text!) {
					if nameField.text != "" {
						return true
					} else {
						singleActionPopup(title: "Please enter your name.", message: nil)
					}
				} else {
					singleActionPopup(title: "Password must be at least 8 characters.", message: nil)
				}
			} else {
				singleActionPopup(title: "Entered passwords do not match.", message: nil)
			}
		} else {
			singleActionPopup(title: "That's not a valid email address.", message: nil)
		}
		return false
	}

	fileprivate func isValidPassword(_ pw : String) -> Bool {
		return pw.count >= 8
	}

	@IBAction func manualRegister() {
		if isValidEntry() {
			attemptManualRegistration()
		}
	}

	fileprivate func attemptManualRegistration() {
		SVProgressHUD.show(withStatus: "Creating your user...")
		DB.shared().createUser(id: idField.text!, name: nameField.text!, authType: .manual, password: passwordField.text!)
	}

	fileprivate func attemptFbRegistration() {
		if FBSDKAccessToken.current() != nil {
			SVProgressHUD.show(withStatus: "Creating your user...")
			Services.shared().fbLogin()
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "registerSegue" {
			let vc = segue.destination as! ProfileImageSelectionViewController
			vc.startingUrl = profileImageUrl
		}
	}

	fileprivate func isValidEmail(testStr:String) -> Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

		let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
		return emailTest.evaluate(with: testStr)
	}
}

extension RegisterViewController : DBDelegate {
	func createUserResponse(success: Bool, user: User?, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			gblUser = user!
			self.performSegue(withIdentifier: "registerSegue", sender: nil)
		} else {
			FBSDKAccessToken.setCurrent(nil)
			FBSDKLoginManager().logOut()
			popupAlert(title: "Failed to register user", message: error, actionTitles: ["Ok"], actions: [nil])
		}
	}
}

extension RegisterViewController : ServicesDelegate {
	func fbLoginResponse(success: Bool, id: String?, name: String?, email: String?) {
		if success {
			profileImageUrl = "http://graph.facebook.com/\(id!)/picture?type=large"
			// TODO: Move Send Bird connection into Services class with delegate response callback
			SBDMain.connect(withUserId: email!, completionHandler: { (newUser, error) in
				SBDMain.updateCurrentUserInfo(withNickname: name!, profileUrl: self.profileImageUrl!, completionHandler: { (error) in
					print("Connected to SendBird and set up user")
				})
			})
			DB.shared().createUser(id: email!, name : name!, authType: .facebook, password: nil)
		} else {
			SVProgressHUD.dismiss()
			self.popupAlert(title: "Failed to register through Facebook", message: "Would you like to try again?", actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
				self.attemptFbRegistration()
				}, nil])
		}
	}
}


