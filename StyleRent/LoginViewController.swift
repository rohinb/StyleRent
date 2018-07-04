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

class LoginViewController: UIViewController {

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
		// Do any additional setup after loading the view, typically from a nib.
		attemptLogin()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if !firstTime {
			attemptLogin()
		}
		firstTime = false
	}

	func attemptLogin() {
		if FBSDKAccessToken.current() != nil {
			
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension LoginViewController : DBDelegate {
	func createUserResponse(success: Bool, error: String?) {
		if success {
			self.performSegue(withIdentifier: "loginSegue", sender: nil)
		} else {
			popupAlert(title: "User Creations failed!", message: error, actionTitles: ["Ok"], actions: [nil])
		}
	}
}

extension LoginViewController : ServicesDelegate {
	func fbLoginResponse(success: Bool, id: String?, name: String?, email: String?) {
		if success {
			// TODO: Handle image
			let profileImageUrl = "http://graph.facebook.com/\(id)/picture?type=square"
			// TODO: Move Send Bird connection into Services class with delegate response callback
			SBDMain.connect(withUserId: email!, completionHandler: { (newUser, error) in
				SBDMain.updateCurrentUserInfo(withNickname: name!, profileUrl: profileImageUrl, completionHandler: { (error) in
					print("Connected to SendBird and set up user")
				})
			})
			//DB.shared().createUser(user: user!)
			//TODO: Make sure user email exists and authType is Facebook
			gblUserId = email!
			gblUserName = name!
			print("FB Login Success!")
		} else {
			self.popupAlert(title: "Failed to login through Facebook", message: "Would you like to try again?", actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
				self.attemptLogin()
				}, nil])
		}
	}
}

