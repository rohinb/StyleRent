//
//  SelectionViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class TextEntryViewController: UIViewController {
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var charsLabel: UILabel!

	var type : DetailType!
	var delegate : SelectionDelegate!
	var charsAllowed : Int?
	var startingValue : String?

    override func viewDidLoad() {
        super.viewDidLoad()
		title = type.rawValue
		let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
		navigationItem.rightBarButtonItem = doneButton
		if startingValue != nil { textView.text = startingValue!}
		if type == .name {
			charsLabel.isHidden = false
			charsAllowed = 40
			textView.returnKeyType = .done
			textView.delegate = self
			updateCharsRemaining()
		}
    }

	func updateCharsRemaining() {
		let remainingChars = charsAllowed! - textView.text.count
		charsLabel.text = "\(remainingChars)"
	}

	@objc func done() {
		if type == .name {
			if textView.text.count > charsAllowed! {
				singleActionPopup(title: "Input too long", message: "Input must be under \(charsAllowed!) characters.")
				return
			}
		}
		if textView.text.count == 0 {
			singleActionPopup(title: "Input cannot be empty", message: nil)
			return
		}
		delegate.madeSelection(type: type, value: textView.text)
		self.navigationController?.popViewController(animated: true)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}

extension TextEntryViewController : UITextViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		if type == .name {
			updateCharsRemaining()
		}
	}

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if (text as NSString).rangeOfCharacter(from: CharacterSet.newlines).location == NSNotFound {
			return true
		}
		textView.resignFirstResponder()
		return false
	}
}

protocol SelectionDelegate {
	func madeSelection(type : DetailType, value : String)
}
