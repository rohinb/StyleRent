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
	var startingValue : String?

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
		let text = options[indexPath.row]
        cell.textLabel?.text = text
		cell.accessoryType = text == startingValue ? .checkmark : .none

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessoryType = .checkmark
		}
		delegate.madeSelection(type: type, value: options[indexPath.row], shouldReload: true)
		self.navigationController?.popViewController(animated: true)
	}

	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessoryType = .none
		}
	}
}
