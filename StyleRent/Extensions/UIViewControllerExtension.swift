//
//  UIViewControllerExtension.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
	func popupAlert(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		for (index, title) in actionTitles.enumerated() {
			let action = UIAlertAction(title: title, style: .default, handler: actions[index])
			alert.addAction(action)
		}
		self.present(alert, animated: true, completion: nil)
	}

	func singleActionPopup(title : String?, message : String?) {
		popupAlert(title: title, message: message, actionTitles: ["Ok"], actions: [nil])
	}
}
