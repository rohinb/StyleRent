//
//  SettingsViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/6/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class SettingsViewController: UITableViewController {

	enum SettingsType : String {
		case terms = "Terms of Service"
		case privacy = "Privacy Policy"
		case logout = "Logout"

		static let allValues : [SettingsType] = [.terms, .privacy, .logout]
	}

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return SettingsType.allValues.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

		let type = SettingsType.allValues[indexPath.row]
		cell.textLabel?.text = type.rawValue

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)

		let type = SettingsType.allValues[indexPath.row]
		switch type {
		case .terms: break
		case .privacy: break
		case .logout: logout()
		}
	}

	fileprivate func logout() {
		popupAlert(title: "Are you sure you want to log out?", message: nil, actionTitles: ["Log out", "Cancel"], actions: [{ (action) in
			self.actuallyLogout()
		}, nil])
	}

	fileprivate func actuallyLogout() {
		gblUser = nil
		FBSDKAccessToken.setCurrent(nil)
		FBSDKLoginManager().logOut()
		self.dismiss(animated: true, completion: nil)
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
