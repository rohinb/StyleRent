//
//  CreateListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3

enum OptionType : String {
	case upload = "Upload"
	case take = "Take"

	static let types = [OptionType.upload, OptionType.take]
}

class CreateListingViewController: UIViewController {
	var images = [UIImage]()
	var uploadFailed = false
	var uploadedCount = 0
	let MAX_IMAGE_COUNT = 5
	@IBOutlet weak var imageCollectionView: UICollectionView!
	let reuseIdentifier = "listingImageCell"

	override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self
		self.imageCollectionView.delegate = self
		self.imageCollectionView.dataSource = self
		self.imageCollectionView.dragDelegate = self
		self.imageCollectionView.dropDelegate = self
		self.imageCollectionView.dragInteractionEnabled = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
		newListing?._imageCount = NSNumber(integerLiteral: self.images.count - 1)
		newListing?._price = 40
		newListing?._size = "M"
		newListing?._sellerId = gblUserId!
		newListing?._type = "Dress test"
		DB.shared().createListing(listing: newListing!)
	}

}

extension CreateListingViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let image = info[UIImagePickerControllerEditedImage] as! UIImage
		images.append(image)
		let newIndexPath = IndexPath(row: images.count - 1, section: 0)
		imageCollectionView.insertItems(at: [newIndexPath])
		picker.dismiss(animated: true, completion: nil)
	}
}

extension CreateListingViewController : DBDelegate {
	func createListingResponse(success : Bool, error : String?) {
		if success {
			images = []
			imageCollectionView.reloadData()
			popupAlert(title: "Listing posted!", message: nil, actionTitles: ["Ok"], actions: [nil])
		} else {
			popupAlert(title: "Failed to save your listing", message: "Please try again soon.", actionTitles: ["Ok"], actions: [nil])
		}
	}
}

extension CreateListingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return min(images.count + 1, MAX_IMAGE_COUNT)
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if images.count < MAX_IMAGE_COUNT && indexPath.row == images.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addOneCell", for: indexPath)
			return cell
		} else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCell
			let image = self.images[indexPath.row]
			cell.theImageView.image = image
			return cell
		}
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.row == images.count {
			let alert = UIAlertController(title: "Select One", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
			alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
			alert.addAction(UIAlertAction(title: OptionType.take.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
				self.takeImage()
			}))
			alert.addAction(UIAlertAction(title: OptionType.upload.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
				self.uploadImage()
			}))

			self.present(alert, animated: true, completion: nil)
		} else {
			popupAlert(title: "Do you want to delete this picture?", message: nil, actionTitles: ["Delete", "Cancel"],
					   actions: [{ (action) in
							self.images.remove(at: indexPath.row)
							self.imageCollectionView.deleteItems(at: [indexPath])
						}, nil])
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
		return !(images.count < MAX_IMAGE_COUNT && indexPath.row == images.count)
	}

	func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
		if images.count < MAX_IMAGE_COUNT && proposedIndexPath.row == images.count {
			return originalIndexPath
		} else {
			return proposedIndexPath
		}
	}

	func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		print("Starting Index: \(sourceIndexPath.item)")
		print("Ending Index: \(destinationIndexPath.item)")
	}
}

extension CreateListingViewController : UICollectionViewDragDelegate, UICollectionViewDropDelegate {
	func collectionView(_ collectionView: UICollectionView, performDropWith
		coordinator: UICollectionViewDropCoordinator) {

		let destinationIndexPath =
			coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)

		switch coordinator.proposal.operation {
		case .move:

			let items = coordinator.items

			for item in items {

				guard let sourceIndexPath = item.sourceIndexPath
					else { return }
				if images.count < MAX_IMAGE_COUNT && destinationIndexPath.row == images.count {
					return
				}

				collectionView.performBatchUpdates({

					let moveImage = images[sourceIndexPath.item]
					images.remove(at: sourceIndexPath.item)
					images.insert(moveImage, at: destinationIndexPath.item)

					collectionView.deleteItems(at: [sourceIndexPath])
					collectionView.insertItems(at: [destinationIndexPath])
				})
				coordinator.drop(item.dragItem,
								 toItemAt: destinationIndexPath)
			}
		default: return
		}
	}

	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate
		session: UIDropSession, withDestinationIndexPath destinationIndexPath:
		IndexPath?) -> UICollectionViewDropProposal {

		if session.localDragSession != nil {
			return UICollectionViewDropProposal(operation: .move,
												intent: .insertAtDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .copy,
												intent: .insertAtDestinationIndexPath)
		}
	}

	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if indexPath.row < images.count { // only move images
			let image = self.images[indexPath.row]
			let itemProvider = NSItemProvider(object: image as UIImage)
			let dragItem = UIDragItem(itemProvider: itemProvider)
			dragItem.localObject = image
			return [dragItem]
		} else {
			return []
		}
	}

}




