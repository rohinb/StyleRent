//
//  SelectionTableViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/27/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class SelectionViewController: UITableViewController {

	var type : DetailType!
	var delegate : SelectionDelegate!
	var options : [String]!

	fileprivate var selectedValue : String?

    override func viewDidLoad() {
        super.viewDidLoad()

		title = type.rawValue
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = options[indexPath.row]

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate.madeSelection(type: type, value: options[indexPath.row])
		self.navigationController?.popViewController(animated: true)
	}
}
