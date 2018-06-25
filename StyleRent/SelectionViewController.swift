//
//  SelectionViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController {
	@IBOutlet weak var textView: UITextView!
	var type : DetailType!
	var delegate : SelectionDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
		title = type.rawValue
		let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
		navigationItem.rightBarButtonItem = doneButton
    }

	@objc func done(sender: UIBarButtonItem) {
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

protocol SelectionDelegate {
	func madeSelection(type : DetailType, value : String)
}
