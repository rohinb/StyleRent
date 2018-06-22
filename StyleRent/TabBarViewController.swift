//
//  TabBarViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/14/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
		// Add messages view
		let vc = GroupChannelListViewController()
		let navController = UINavigationController()
		navController.viewControllers = [vc]
		let item = UITabBarItem(title: "Conversations", image: nil, selectedImage: nil)
		navController.tabBarItem = item
		navController.title = "Conversations"
		self.viewControllers?.append(navController)
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
