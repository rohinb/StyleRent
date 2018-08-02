//
//  FormCell.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/24/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class FormCell: UITableViewCell {
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var field: UITextField!
	var delegate : SelectionDelegate?
	var detailType : DetailType?

	override func awakeFromNib() {
        super.awakeFromNib()
		field.delegate = self
		field.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

	@objc fileprivate func textFieldDidChange(_ textField: UITextField) {
		delegate?.madeSelection(type: detailType!, value: textField.text!, shouldReload: false)
	}

	func addDoneButton(target : UIView) {
		let keyboardToolbar = UIToolbar()
		keyboardToolbar.sizeToFit()
		let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
											target: nil, action: nil)
		let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
											target: target, action: #selector(UIView.endEditing(_:)))
		keyboardToolbar.items = [flexBarButton, doneBarButton]
		field.inputAccessoryView = keyboardToolbar
	}
}

extension FormCell : UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		delegate?.madeSelection(type: detailType!, value: textField.text!, shouldReload: true)
	}
}
