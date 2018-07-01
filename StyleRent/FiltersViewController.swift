//
//  FiltersViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/1/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class FiltersViewController: UITableViewController {
	var delegate : FiltersDelegate?
	var currentDetail = ListingDetail()

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.register(UINib(nibName: "DetailCell", bundle: nil), forCellReuseIdentifier: "DetailCell")
        // Do any additional setup after loading the view.
    }

	func applyFilter() {
		self.dismiss(animated: true) {
			self.delegate?.filtersUpdated(newDetail: self.currentDetail)
		}
	}
    
	@IBAction func cancelPressed(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") as! DetailCell
		if indexPath.row == 0 {
			cell.titleLabel.text = "Category"
			cell.detailLabel.text = currentDetail.category == nil ? "All" : currentDetail.category?.rawValue
		} else if indexPath.row == 1 {
			cell.titleLabel.text = "Size"
			cell.detailLabel.text = currentDetail.size ?? "All"
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "SelectionVC") as! SelectionViewController
		vc.delegate = self
		if indexPath.row == 0 {
			vc.type = .category
			vc.options = ListingCategory.allValues.map({ (category) -> String in
				return category.rawValue
			})
		} else if indexPath.row == 1 {
			vc.type = .size
			if currentDetail.category == nil {
				singleActionPopup(title: "You must first select a category", message: nil)
				return
			}
			vc.options = ClothingUtils.getSizeOptions(for: currentDetail.category!)
		} else {
			return
		}
		self.navigationController?.pushViewController(vc, animated: true)
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
}

extension FiltersViewController : SelectionDelegate {
	func madeSelection(type: DetailType, value: String) {
		switch type {
		case .category: currentDetail.category = ListingCategory(rawValue: value)!
		case .size: currentDetail.size = value
		default: return
		}
		applyFilter()
	}
}

protocol FiltersDelegate {
	func filtersUpdated(newDetail : ListingDetail)
}
