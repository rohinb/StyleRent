//
//  ProfileImageSelectionViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/7/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import SVProgressHUD

class ProfileImageSelectionViewController: UIViewController {
	var startingUrl : String?
	@IBOutlet weak var imageView: UIImageView!
	let placeholderImage = #imageLiteral(resourceName: "placeholder")

    override func viewDidLoad() {
        super.viewDidLoad()
		Services.shared().delegate = self
		imageView.image = placeholderImage
		if let url = startingUrl {
			SVProgressHUD.show(withStatus: "Downloading image...")
			Utilities.getDataFromUrl(url: URL(string: url)!) { (data, response, error) in
				DispatchQueue.main.async {
					SVProgressHUD.dismiss()
					guard let data = data, error == nil else {
						self.singleActionPopup(title: "Failed to fetch profile picture.", message: "Please upload or take a picture")
						return
					}
					self.imageView.image = UIImage(data: data)
				}
			}
		}


		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
		imageView.isUserInteractionEnabled = true
		imageView.addGestureRecognizer(tapGestureRecognizer)
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if gblUser == nil {
			self.dismiss(animated: false, completion: nil)
		}
	}

	@objc fileprivate func imageViewTapped() {
		let alert = UIAlertController(title: "Select One", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		alert.addAction(UIAlertAction(title: PhotoOptionType.take.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
			self.takeImage()
		}))
		alert.addAction(UIAlertAction(title: PhotoOptionType.upload.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
			self.uploadImage()
		}))

		self.present(alert, animated: true, completion: nil)
	}

	func takeImage() {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .camera
			imagePicker.allowsEditing = true
			self.present(imagePicker, animated: true, completion: nil)
		}
	}

	func uploadImage() {
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .photoLibrary
			imagePicker.allowsEditing = true
			self.present(imagePicker, animated: true, completion: nil)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func done(_ sender: Any) {
		if imageView.image != placeholderImage {
			SVProgressHUD.show(withStatus: "Saving your profile photo...")
			let image = imageView.image!
			Services.shared().uploadImageToS3(image: image, key: "profile-images/\(gblUser._id!)")
		} else {
			singleActionPopup(title: "You must choose a profile picture", message: nil)
		}
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

extension ProfileImageSelectionViewController : ServicesDelegate {
	func uploadImageResponse(success: Bool) {
		SVProgressHUD.dismiss()
		if success {
			performSegue(withIdentifier: "finishRegistrationSegue", sender: nil)
		} else {
			singleActionPopup(title: "Failed to upload your profile image", message: "Please try again.")
		}
	}
}

extension ProfileImageSelectionViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let image = info[UIImagePickerControllerEditedImage] as! UIImage
		imageView.image = image
		picker.dismiss(animated: true, completion: nil)
	}
}
