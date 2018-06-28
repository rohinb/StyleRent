//
//  CreateListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3

enum PhotoOptionType : String {
	case upload = "Upload"
	case take = "Take"

	static let types = [PhotoOptionType.upload, PhotoOptionType.take]
}

enum DetailType : String {
	case name = "Name"
	case description = "Description"
	case category = "Category"
	case size = "Size"
	case originalPrice = "Original Price"
	case listingPrice = "Listing Price"
	case earnings = "Your earnings"
}

enum SectionType : Int {
	case name = 0
	case description
	case details
	case price

	var rows : [DetailType] {
		switch self {
		case .name: return [.name]
		case .description: return [.description]
		case .details: return [.category, .size]
		case .price: return [.originalPrice, .listingPrice, .earnings]
		}
	}

	var header : String? {
		switch self {
		case .name: return "Details"
		case .description: return nil
		case .details: return nil
		case .price: return nil
		}
	}

	var rowHeight : CGFloat {
		switch self {
		case .name: return 40
		case .description: return 70
		case .details: return 35
		case .price: return 35
		}
	}
}


class CreateListingViewController: UIViewController {
	var images = [UIImage]()
	var uploadFailed = false
	var uploadedCount = 0
	let MAX_IMAGE_COUNT = 5
	@IBOutlet weak var imageCollectionView: UICollectionView!
	@IBOutlet weak var tableView: UITableView!
	let reuseIdentifier = "listingImageCell"
	var newListing = Listing()

	override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self

		//hideKeyboardWhenTappedAround()

		imageCollectionView.delegate = self
		imageCollectionView.dataSource = self
		imageCollectionView.dragDelegate = self
		imageCollectionView.dropDelegate = self
		imageCollectionView.dragInteractionEnabled = true

		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(UINib(nibName: "TextViewCell", bundle: nil), forCellReuseIdentifier: "TextViewCell")
		tableView.register(UINib(nibName: "FormCell", bundle: nil), forCellReuseIdentifier: "FormCell")

		title = "Post Listing"
		let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveListing))
		navigationItem.rightBarButtonItem = doneButton
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		DB.shared().delegate = self
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

	@objc func saveListing(sender: UIBarButtonItem) {
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
		newListing?._id = id
		newListing?._latitude = 37.2657536962002
		newListing?._longitude = -121.971246711695
		newListing?._imageCount = NSNumber(integerLiteral: self.images.count - 1)
		newListing?._sellerId = gblUserId!
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
			newListing = Listing()
			tableView.reloadData()
			imageCollectionView.reloadData()
			singleActionPopup(title: "Listing posted!", message: nil)
		} else {
			singleActionPopup(title: "Failed to save your listing", message: "Please try again soon.")
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
			alert.addAction(UIAlertAction(title: PhotoOptionType.take.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
				self.takeImage()
			}))
			alert.addAction(UIAlertAction(title: PhotoOptionType.upload.rawValue, style: UIAlertActionStyle.default, handler: { (action) in
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

extension CreateListingViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let type = SectionType(rawValue: indexPath.section)!
		switch type {
		case .name:
			let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
			cell.field.placeholder = "What are you selling?"
			cell.field.text = newListing?._name
			return cell
		case .description:
			let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
			cell.field.placeholder = "Describe it!"
			cell.field.text = newListing?._description
			return cell
		case .details:
			let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell") as! FormCell
			let detailType = type.rows[indexPath.row]
			cell.nameLabel.text = detailType.rawValue
			switch detailType {
			case .category: cell.field.text = newListing!._category
			case .size: cell.field.text = newListing!._size
			default: break
			}
			cell.field.placeholder = "required"
			return cell
		case .price:
			let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell") as! FormCell
			let detailType = type.rows[indexPath.row]
			cell.nameLabel.text = detailType.rawValue
			switch detailType {
			case .originalPrice: cell.field.text = newListing?._originalPrice != nil ? String(describing: newListing!._originalPrice!) : ""
			case .listingPrice: cell.field.text = newListing?._price != nil ? String(describing: newListing!._price!) : ""
			default: break
			}
			cell.field.placeholder = "required"
			return cell
		}
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 4
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let type = SectionType(rawValue: indexPath.section)?.rows[indexPath.row]
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		if type == .name || type == .description || type == .originalPrice || type == .listingPrice{
			let vc = storyboard.instantiateViewController(withIdentifier: "TextEntryVC") as! TextEntryViewController
			vc.delegate = self
			vc.type = type
			self.navigationController?.pushViewController(vc, animated: true)
		} else {
			let vc = storyboard.instantiateViewController(withIdentifier: "SelectionVC") as! SelectionViewController
			vc.delegate = self
			vc.type = type
			if type == .category {
				vc.options = ListingCategory.allValues.map({ (category) -> String in
					return category.rawValue
				})
			} else if type == .size {
				if newListing!._category == nil {
					singleActionPopup(title: "You must first select a category", message: nil)
				}
				vc.options = ClothingUtils.getSizeOptions(for: ListingCategory(rawValue: newListing!._category!)!)
			} else {
				vc.options = []
			}
			self.navigationController?.pushViewController(vc, animated: true)
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let type = SectionType(rawValue: section)!
		return type.rows.count
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let type = SectionType(rawValue: indexPath.section)!
		return type.rowHeight
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let type = SectionType(rawValue: section)!
		return type.header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		let type = SectionType(rawValue: section)!
		if type.header == nil {
			return 5
		} else {
			return 40
		}
	}
}

extension CreateListingViewController : SelectionDelegate {
	func madeSelection(type: DetailType, value: String) {
		switch type {
		case .category: newListing!._category = value
		case .description: newListing!._description = value
		case .name: newListing!._name = value
		case .listingPrice: newListing!._price = NSNumber(integerLiteral: Int(value)!)
		case .originalPrice: newListing!._originalPrice = NSNumber(integerLiteral: Int(value)!)
		case .size: newListing!._size = value
		default: break
		}
		self.tableView.reloadData()
	}
}
