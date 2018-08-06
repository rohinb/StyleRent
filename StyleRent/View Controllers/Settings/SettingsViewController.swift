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

	fileprivate enum SettingsType : String {
		case guide = "Your Guide to StyleRent"
		case myCloset = "My Closet"
		case myBalance = "My Balance"
		case terms = "Terms of Service"
		case privacy = "Privacy Policy"
		case logout = "Logout"

		static let allValues : [[SettingsType]] = [[.guide, .myBalance], [.myCloset], [.terms, .privacy], [.logout]]
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		let editButton = UIBarButtonItem(title: "My Balance", style: UIBarButtonItemStyle.plain, target: self, action: #selector(viewBalance))
		navigationItem.setRightBarButton(editButton, animated: true)
    }

	@objc fileprivate func viewBalance() {
		
	}

	fileprivate func showMyCloset() {
		let vc = Utilities.getClosetVcFor(user: gblUser)
		self.navigationController?.pushViewController(vc, animated: true)
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
}

// MARK: - Table view
extension SettingsViewController {

	override func numberOfSections(in tableView: UITableView) -> Int {
		return SettingsType.allValues.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return SettingsType.allValues[section].count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()

		let type = SettingsType.allValues[indexPath.section][indexPath.row]
		cell.textLabel?.text = type.rawValue

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)

		let type = SettingsType.allValues[indexPath.section][indexPath.row]
		switch type {
		case .guide: break
		case .myBalance: viewBalance()
		case .myCloset: showMyCloset()
		case .terms: break
		case .privacy: break
		case .logout: logout()
		}
	}
}
