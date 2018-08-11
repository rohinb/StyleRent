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
		tableView.register(UINib(nibName: "SliderCell", bundle: nil), forCellReuseIdentifier: "SliderCell")
        // Do any additional setup after loading the view.
    }

	func applyFilter() {
		self.dismiss(animated: true) {
			self.delegate?.filtersUpdated(newDetail: self.currentDetail)
		}
	}
    
	@IBAction func cancelPressed(_ sender: Any) {
		applyFilter()
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") as! DetailCell
			cell.titleLabel.text = "Category"
			cell.detailLabel.text = currentDetail.category == nil ? "All" : currentDetail.category?.rawValue
			return cell
		} else if indexPath.row == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") as! DetailCell
			cell.titleLabel.text = "Size"
			cell.detailLabel.text = currentDetail.size ?? "All"
			return cell
		} else if indexPath.row == 2 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell") as! SliderCell
			cell.titleString = "Max Distance"
			cell.slider.minimumValue = 1
			cell.slider.maximumValue = 20
			cell.slider.setValue(Float(currentDetail.distanceRadius), animated: false)
			cell.sliderValueChanged(sender: cell.slider)
			cell.delegate = self
			return cell
		} else {
			return UITableViewCell()
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "SelectionVC") as! SelectionViewController
		vc.delegate = self
		if indexPath.row == 0 {
			vc.type = .category
			vc.startingValue = currentDetail.category?.rawValue
			vc.options = ListingCategory.allValues.map({ (category) -> String in
				return category.rawValue
			})
		} else if indexPath.row == 1 {
			vc.type = .size
			vc.startingValue = currentDetail.size
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
	func madeSelection(type: DetailType, value: String, shouldReload : Bool) {
		switch type {
		case .category:
			if value != currentDetail.category?.rawValue {
				currentDetail.size = nil
			}
			currentDetail.category = ListingCategory(rawValue: value)!
		case .size: currentDetail.size = value
		default: return
		}
		applyFilter()
	}
}

extension FiltersViewController : SliderCellDelegate {
	func sliderValueChanged(val: Float) {
		currentDetail.distanceRadius = Double(val)
	}
}

protocol FiltersDelegate {
	func filtersUpdated(newDetail : ListingDetail)
}
