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

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.delegate = self
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
						print("failed to upload images")
					} else {
						let newListing = Listing()
						newListing?._id = newListingId
						newListing?._latitude = 37.2657536962002
						newListing?._longitude = -121.971246711695
						newListing?._description = "testing listing"
						newListing?._imageCount = NSNumber(integerLiteral: self.images.count)
						newListing?._price = 40
						newListing?._size = "Medium"
						newListing?._sellerId = gblUserId!
						newListing?._type = "Dress test"
						DB.createListing(listing: newListing!)
					}
				})
			}

			let transferUtility = AWSS3TransferUtility.default()

			transferUtility.uploadData(data,
									   //bucket: Constants.listingImageBucket,
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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
			self.navigationController?.popViewController(animated: true)
		} else {
			popupAlert(title: "Failed to save your listing", message: "Please try again soon.", actionTitles: ["Ok"], actions: [nil])
		}
	}
}



