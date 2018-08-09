//
//  CreateListingViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/25/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3
import SVProgressHUD
import CoreLocation
import Photos
import Finjinon

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

fileprivate enum SectionType : Int {
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
		case .name: return 45
		case .description: return 70
		case .details: return 40
		case .price: return 40
		}
	}

	var footer : String? {
		if self == .price {
			return "We take no cut! All the money from renting goes to you!"
		}
		return nil
	}

	static let count: Int = {
		var max: Int = 0
		while let _ = SectionType(rawValue: max) { max += 1 }
		return max
	}()
}

class CreateListingViewController: UIViewController {
	@IBOutlet weak var imageCollectionView: UICollectionView!
	@IBOutlet weak var tableView: UITableView!

	fileprivate let MAX_IMAGE_COUNT = 5
	fileprivate let reuseIdentifier = "listingImageCell"

	fileprivate var uploadFailed = false
	fileprivate var uploadedCount = 0

	var initialImages = [UIImage]()
	var newListing = Listing()
	var isEditView = false
	var parentVC : ListingDetailsViewController?
	var assets: [Asset] = []
	let captureController = PhotoCaptureViewController()

	override func viewDidLoad() {
        super.viewDidLoad()
		//hideKeyboardWhenTappedAround()
		for i in initialImages {
			captureController.createAssetFromImage(i) { (asset) in
				self.assets.append(asset)
			}
		}

		captureController.delegate = self
		imageCollectionView.delegate = self
		imageCollectionView.dataSource = self

		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(UINib(nibName: "TextViewCell", bundle: nil), forCellReuseIdentifier: "TextViewCell")
		tableView.register(UINib(nibName: "FormCell", bundle: nil), forCellReuseIdentifier: "FormCell")

		title = isEditView ? "Edit Listing" : "Post Listing"
		let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePressed))
		navigationItem.rightBarButtonItem = doneButton
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: Keyboard Notifications

	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
			tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
		}
	}

	@objc func keyboardWillHide(notification: NSNotification) {
		UIView.animate(withDuration: 0.2, animations: {
			// For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
			self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
		})
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		DB.shared().delegate = self
		Services.shared().delegate = self
	}

	@objc fileprivate func donePressed() {
		self.view.endEditing(true)
		let isValidated = newListing!._category != nil &&
							newListing!._description != nil &&
							newListing!._name != nil &&
							newListing!._originalPrice != nil &&
							newListing!._price != nil &&
							newListing!._size != nil
		if isValidated {
			saveListing()
		} else {
			singleActionPopup(title: "Please complete all fields.", message: nil)
		}
	}

	fileprivate func getImages(completionHandler : @escaping ([UIImage]) -> Void) {
		var images = [Int: UIImage]()
		let g = DispatchGroup()
		for i in 0..<assets.count {
			g.enter()
			let asset = assets[i]
			asset.originalImage { (image) in
				images[i] = image
				g.leave()
			}
		}
		g.notify(queue: DispatchQueue.main) {
			var arr = [UIImage]()
			for i in 0..<self.assets.count {
				arr.append(images[i]!)
			}
			completionHandler(arr)
		}
	}

	fileprivate func saveListing() {
		// start uploading images to S3
		getImages { (images) in
			var images = images
			guard let firstImage = images.first else {
				self.singleActionPopup(title: "You must upload at least one image!", message: nil)
				return
			}

			SVProgressHUD.show(withStatus: "Creating listing...")
			self.uploadFailed = false
			self.uploadedCount = 0
			let thumbnailSideLength = ListingsViewController.kCellHeight - 60.0
			let thumbnailSize = CGSize(width: thumbnailSideLength, height: thumbnailSideLength)
			images.insert(firstImage.resizeImageWith(newSize: thumbnailSize), at: 0)

			let newListingId = self.isEditView ? self.newListing!._id! : UUID().uuidString
			self.newListing?._id = newListingId
			for (index, image) in images.enumerated() {
				Services.shared().uploadImageToS3(image: image, key: "listing-images/\(newListingId)-\(index + 1)")
			}
		}
	}

	fileprivate func writeListing() {
		// use real coords
		newListing?._latitude = NSNumber(value: gblCurrentLocation.coordinate.latitude)
		newListing?._longitude = NSNumber(value: gblCurrentLocation.coordinate.longitude)
		newListing?._blockId = Utilities.getBlockIdFor(lat: gblCurrentLocation.coordinate.latitude, long: gblCurrentLocation.coordinate.longitude)
		newListing?._imageCount = NSNumber(integerLiteral: self.assets.count)
		newListing?._sellerId = gblUser._id!
		DB.shared().createListing(listing: newListing!)
	}

	fileprivate func getCurrInfo(for type: DetailType) -> String? {
		switch type {
		case .category: return newListing!._category
		case .description: return newListing!._description
		case .name: return newListing!._name
		case .listingPrice: return newListing?._price != nil ? String(describing: newListing!._price!) : ""
		case .originalPrice: return newListing?._originalPrice != nil ? String(describing: newListing!._originalPrice!) : ""
		case .size: return newListing!._size
		default: return nil
		}
	}

	fileprivate func getNSNumForString(value : String?) -> NSNumber? {
		return (value == nil || value == "") ? nil : NSNumber(integerLiteral: Int(value!)!)
	}

	fileprivate func setCurrInfo(info value : String?, for type: DetailType) {
		switch type {
		case .category: newListing!._category = value
		case .description: newListing!._description = value
		case .name: newListing!._name = value
		case .listingPrice: newListing!._price = getNSNumForString(value: value)
		case .originalPrice: newListing!._originalPrice = getNSNumForString(value: value)
		case .size: newListing!._size = value
		default: break
		}
	}
}

extension CreateListingViewController : DBDelegate {
	func createListingResponse(success : Bool, error : String?) {
		SVProgressHUD.dismiss()
		if success {
			if isEditView {
				if let vc = self.parentVC {
					vc.listing = self.newListing
					vc.update()
				}
				self.navigationController?.popViewController(animated: true)
			} else {
				assets = []
				newListing = Listing()
				tableView.reloadData()
				imageCollectionView.reloadData()
				singleActionPopup(title: "Listing posted!", message: nil)
			}
		} else {
			singleActionPopup(title: "Failed to save your listing", message: "Please try again soon.")
		}
	}
}

extension CreateListingViewController : ServicesDelegate {
	func uploadImageResponse(success: Bool) {
		if !success {
			SVProgressHUD.dismiss()
			popupAlert(title: "Uh-oh, we failed to the upload images of your listing.", message: "Please try again later.", actionTitles: ["Ok"], actions: [nil])
			uploadFailed = true
		} else {
			uploadedCount += 1
			if !uploadFailed && uploadedCount == assets.count {
				print("Last image uploaded!")
				writeListing()
			}
		}
	}
}

extension CreateListingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return min(assets.count + 1, MAX_IMAGE_COUNT)
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if assets.count < MAX_IMAGE_COUNT && indexPath.row == assets.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addOneCell", for: indexPath)
			return cell
		} else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCell
			let asset = assets[indexPath.row]
			cell.theImageView?.image = nil
			asset.imageWithWidth(64, result: { image in
				cell.theImageView?.image = image
				cell.setNeedsLayout()
			})
			return cell
		}
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.row == assets.count {
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				let photos = PHPhotoLibrary.authorizationStatus()
				if photos == .notDetermined {
					PHPhotoLibrary.requestAuthorization({status in
						if status == .authorized{
							self.present(self.captureController, animated: true, completion: nil)
						} else {}
					})
				} else {
					self.present(self.captureController, animated: true, completion: nil)
				}
			}
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
		return !(assets.count < MAX_IMAGE_COUNT && indexPath.row == assets.count)
	}

	func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
		if assets.count < MAX_IMAGE_COUNT && proposedIndexPath.row == assets.count {
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

extension CreateListingViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let type = SectionType(rawValue: indexPath.section)!
		let detailType = type.rows[indexPath.row]
		let text = getCurrInfo(for: detailType)
		switch type {
		case .name:
			let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
			cell.field.isUserInteractionEnabled = false
			cell.field.placeholder = "What are you selling?"
			cell.field.text = text
			return cell
		case .description:
			let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
			cell.field.isUserInteractionEnabled = false
			cell.field.placeholder = "Describe it!"
			cell.field.text = text
			return cell
		case .details:
			let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell") as! FormCell
			cell.nameLabel.text = detailType.rawValue
			cell.field.isUserInteractionEnabled = false
			cell.field.text = text
			cell.field.placeholder = "required"
			return cell
		case .price:
			let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell") as! FormCell
			let detailType = type.rows[indexPath.row]
			cell.delegate = self
			cell.detailType = detailType
			cell.nameLabel.text = detailType.rawValue
			cell.field.keyboardType = .numberPad
			cell.addDoneButton(target: self.view)
			cell.field.returnKeyType = .done
			switch detailType {
			case .earnings:
				cell.field.text = getCurrInfo(for: .listingPrice) // we don't take a share yet
				cell.field.isUserInteractionEnabled = false
				cell.field.placeholder = "auto-calculated"
			case .listingPrice:
				cell.field.text = text
				cell.field.isUserInteractionEnabled = true
				cell.field.placeholder = "required"
			case .originalPrice:
				cell.field.text = text
				cell.field.isUserInteractionEnabled = true
				cell.field.placeholder = "required"
			default: break
			}
			return cell
		}
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return SectionType.count
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let type : DetailType = SectionType(rawValue: indexPath.section)!.rows[indexPath.row]
		let currInfo = getCurrInfo(for: type)
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		switch type {
		case .name, .description:
			let vc = storyboard.instantiateViewController(withIdentifier: "TextEntryVC") as! TextEntryViewController
			vc.delegate = self
			vc.type = type
			vc.startingValue = currInfo
			self.navigationController?.pushViewController(vc, animated: true)
		case .listingPrice, .originalPrice:
			DispatchQueue.main.async {
				let cell = tableView.cellForRow(at: indexPath) as! FormCell
				cell.detailType = type
				cell.field.becomeFirstResponder()
			}
		case .earnings:
			break
		case .size, .category:
			let vc = storyboard.instantiateViewController(withIdentifier: "SelectionVC") as! SelectionViewController
			vc.delegate = self
			vc.type = type
			vc.startingValue = currInfo
			if type == .category {
				vc.options = ListingCategory.allValues.map({ (category) -> String in
					return category.rawValue
				})
			} else if type == .size {
				if newListing!._category == nil {
					singleActionPopup(title: "You must first select a category", message: nil)
					return
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

	func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		let type = SectionType(rawValue: section)!
		return type.footer
	}
}


extension CreateListingViewController: PhotoCaptureViewControllerDelegate {

	func photoCaptureViewController(_ controller: PhotoCaptureViewController, cellForItemAtIndexPath indexPath: IndexPath) -> PhotoCollectionViewCell? {
		return controller.dequeuedReusableCellForClass(PhotoCollectionViewCell.self, indexPath: indexPath) { cell in
			let asset = self.assets[indexPath.item]
			// Set a thumbnail form the source image, or add your own network fetch code etc
			if let _ = asset.imageURL {

			} else {
				asset.imageWithWidth(cell.imageView.bounds.width) { image in
					cell.imageView.image = image
				}
			}
		}
	}

	func photoCaptureViewControllerDidFinish(_: PhotoCaptureViewController) {
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, didSelectAssetAtIndexPath indexPath: IndexPath) {
		NSLog("tapped in \(indexPath.row)")
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, didFailWithError error: NSError) {
		NSLog("failure: \(error)")
	}

	func photoCaptureViewControllerNumberOfAssets(_: PhotoCaptureViewController) -> Int {
		return assets.count
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, assetForIndexPath indexPath: IndexPath) -> Asset {
		return assets[indexPath.item]
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, didAddAsset asset: Asset) {
		assets.append(asset)
		imageCollectionView.reloadData()
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, deleteAssetAtIndexPath indexPath: IndexPath) {
		assets.remove(at: indexPath.item)
		imageCollectionView.reloadData()
	}

	func photoCaptureViewController(_: PhotoCaptureViewController, canMoveItemAtIndexPath _: IndexPath) -> Bool {
		return true
	}
	func photoCaptureViewController(_ controller: PhotoCaptureViewController, didMoveItemFromIndexPath fromIndexPath: IndexPath, toIndexPath: IndexPath) {
		let asset = assets[fromIndexPath.row]
		assets.remove(at: fromIndexPath.row)
		assets.insert(asset, at: toIndexPath.row)
		imageCollectionView.reloadData()
	}
}

extension CreateListingViewController : SelectionDelegate {
	func madeSelection(type: DetailType, value: String, shouldReload : Bool) {
		setCurrInfo(info: value, for: type)
		if type == .category {
			setCurrInfo(info: nil, for: .size)
		}
		if shouldReload {
			self.tableView.reloadData()
		}
	}
}
