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

		let loginButton = FBSDKLoginButton()
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
			FBSDKGraphRequest(graphPath: "me", parameters: nil).start { (conn, result, err) in
				if err != nil {
					self.popupAlert(title: "Failed to login through Facebook", message: "Would you like to try again?", actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
						self.attemptLogin()
						}, nil])
				} else {
					let user = User()
					if let results = result as? [String : String] {
						user?._id = results["id"]
						user?._name = results["name"]
					}
					SBDMain.connect(withUserId: user!._id!, completionHandler: { (newUser, error) in
						SBDMain.updateCurrentUserInfo(withNickname: user!._name, profileUrl: "http://graph.facebook.com/\(user!._id!)/picture?type=square", completionHandler: { (error) in
							print("Connected to SendBird and set up user")
						})
					})
					DB.shared().createUser(user: user!)
					gblUserId = user!._id!
					gblUserName = user!._name!
					print("FB Login Success!")
				}
			}
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

