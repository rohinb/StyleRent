//
//  CreateListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3

class CreateListingViewController: UIViewController {
	var images = [UIImage]()
	var uploadFailed = false
	var uploadedCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func loadImage(_ sender: Any) {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .camera
			imagePicker.allowsEditing = true
			self.present(imagePicker, animated: true, completion: nil)
		}
	}

	@IBAction func uploadImage(_ sender: Any) {
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .photoLibrary
			imagePicker.allowsEditing = true
			self.present(imagePicker, animated: true, completion: nil)
		}
	}

	@IBAction func saveListing(_ sender: Any) {
		// start uploading images to S3
		guard let firstImage = images.first else {
			popupAlert(title: "You must upload at least one image!", message: nil, actionTitles: ["Ok"], actions: [nil])
			return
		}
		uploadFailed = false
		uploadedCount = 0
		let thumbnailSideLength = ListingViewController.kCellHeight - 60.0
		let thumbnailSize = CGSize(width: thumbnailSideLength, height: thumbnailSideLength)
		images.insert(firstImage.resizeImageWith(newSize: thumbnailSize), at: 0)

		let newListingId = UUID().uuidString
		for (index, image) in images.enumerated() {
			let data = UIImageJPEGRepresentation(image, 0.7)!

			let expression = AWSS3TransferUtilityUploadExpression()
			expression.progressBlock = {(task, progress) in
				DispatchQueue.main.async(execute: {
					print("Progress upload image \(index + 1) / \(self.images.count): \(progress.fractionCompleted)")
				})
			}

			var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
			completionHandler = { (task, error) -> Void in
				DispatchQueue.main.async(execute: {
					if error != nil {
						self.popupAlert(title: "Uh-oh, we failed to the upload images of your listing.", message: "Please try again later.", actionTitles: ["Ok"], actions: [nil])
						self.uploadFailed = true
					} else {
						self.uploadedCount += 1
						if !self.uploadFailed && self.uploadedCount == self.images.count {
							print("Last image uploaded!")
							self.writeListing(id: newListingId)
						}
					}
				})
			}

			let transferUtility = AWSS3TransferUtility.default()

			transferUtility.uploadData(data,
									   key: "listing-images/\(newListingId)-\(index + 1)",
									   contentType: "image/jpg",
									   expression: expression,
									   completionHandler: completionHandler).continueWith {
										(task) -> AnyObject? in
										if let error = task.error {
											print("Error: \(error.localizedDescription)")
										}

										if let _ = task.result {
											print(task)
										}
										return nil;
			}
		}
	}

	func writeListing(id : String) {
		let newListing = Listing()
		newListing?._id = id
		newListing?._name = "Gucci shirt"
		newListing?._latitude = 37.2657536962002
		newListing?._longitude = -121.971246711695
		newListing?._description = "testing listing"
		newListing?._imageCount = NSNumber(integerLiteral: self.images.count)
		newListing?._price = 40
		newListing?._size = "M"
		newListing?._sellerId = gblUserId!
		newListing?._type = "Dress test"
		DB.shared().createListing(listing: newListing!)
	}

}

extension CreateListingViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		images.append(image)
		picker.dismiss(animated: true, completion: nil)
	}
}

extension CreateListingViewController : DBDelegate {
	func createListingResponse(success : Bool, error : String?) {
		if success {
			images = []
			popupAlert(title: "Listing posted!", message: nil, actionTitles: ["Ok"], actions: [nil])
		} else {
			popupAlert(title: "Failed to save your listing", message: "Please try again soon.", actionTitles: ["Ok"], actions: [nil])
		}
	}
}



