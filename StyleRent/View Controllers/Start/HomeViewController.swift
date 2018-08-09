//
//  HomeViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/6/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreLocation

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self
		Services.shared().delegate = self
		gblLocManager.requestWhenInUseAuthorization()
		var userNotificationTypes : UIUserNotificationType
		userNotificationTypes = [.alert , .badge , .sound]
		let notificationSettings = UIUserNotificationSettings.init(types: userNotificationTypes, categories: nil)
		UIApplication.shared.registerUserNotificationSettings(notificationSettings)
		UIApplication.shared.registerForRemoteNotifications()
		tryLogin()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	fileprivate func tryLogin() {
		if let userId = Defaults.standard.string(forKey: Defaults.userIdKey) {
			SVProgressHUD.show(withStatus: "Logging you in...")
			DB.shared().getUser(with: userId)
		}
	}
}

extension HomeViewController : DBDelegate {
	func getUserResponse(success: Bool, user: User?, error: String?) {
		if success {
			gblUser = user!
			Services.shared().connectSendBird(user: user!, imageUrlString: Utilities.getUrlForUserPicture(userId: user!._id!).absoluteString)
		} else {
			SVProgressHUD.dismiss()
			popupAlert(title: "Failed to log you in automatically", message: error, actionTitles: ["Try Again", "Cancel"], actions: [{ (action) in
				self.tryLogin()
			}, nil])
		}
	}
}

extension HomeViewController : ServicesDelegate {
	func connectSendBirdResponse(success: Bool) {
		SVProgressHUD.dismiss()
		if success {
			performSegue(withIdentifier: "autoLoginSegue", sender: nil)
		} else {
			singleActionPopup(title: "Failed to connect send bird.", message: nil)
		}
	}
}
