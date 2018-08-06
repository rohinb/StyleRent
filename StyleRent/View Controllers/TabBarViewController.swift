//
//  TabBarViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/14/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialSnackbar

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
		gblTabBarController = self
		title = "Account"
		// Add messages view
		let vc = GroupChannelListViewController()
		let navController = UINavigationController()
		navController.viewControllers = [vc]
		let item = UITabBarItem(title: "Conversations", image: nil, selectedImage: nil)
		navController.tabBarItem = item
		navController.title = "Conversations"
		self.viewControllers?.insert(navController, at: self.viewControllers!.count - 1)
		let _ = vc.view // pre-load the messages ui
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func receivedMessage(text : String) {
		let message = MDCSnackbarMessage()
		message.text = text
		let action = MDCSnackbarMessageAction()
		let actionHandler = {() in
			self.selectedIndex = 3 // go to conversations page
		}
		action.handler = actionHandler
		action.title = "View"
		message.action = action
		MDCSnackbarManager.setBottomOffset(50)
		MDCSnackbarManager.show(message)
	}

}
