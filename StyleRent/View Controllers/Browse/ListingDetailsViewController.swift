//
//  ListingDetailsController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3
import SendBirdSDK
import SVProgressHUD
import Nuke

class ListingDetailsViewController: UIViewController {
	@IBOutlet weak var sellerImageView: UIImageView!
	@IBOutlet weak var sellerNameLabel: UILabel!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageContainerView: UIView!
	@IBOutlet weak var listingNameLabel: UILabel!
	@IBOutlet var listingPriceLabels: [UILabel]!
	@IBOutlet var originalPriceLabels: [UILabel]!
	@IBOutlet weak var sizeLabel: UILabel!
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var categoryLabel: UILabel!
	@IBOutlet weak var messageButton: UIButton!
	@IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!

	fileprivate let imagePadding = CGFloat(20)

	fileprivate var isLoadingImages = false
	fileprivate var seller : User?
	fileprivate var createdChannel : SBDGroupChannel!
	fileprivate var wantToEdit = false
	fileprivate var wantToRentOut = false
	fileprivate var wantToDelete = false

	var listing : Listing!
	var images = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
		DB.shared().delegate = self

		if listing._description != nil {
			renderListing()
		} else {
			SVProgressHUD.show(withStatus: "Loading listing details...")
			DB.shared().getListing(with: listing._id!)
		}

		if listing._sellerId! == gblUser._id! {
			messageButton.setTitle("Rent this out", for: UIControlState())
			let editButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target: self, action: #selector(editPressed))
			let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(deletePressed))
			navigationItem.setRightBarButtonItems([editButton, deleteButton], animated: false)
		}

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showSellerCloset))
		sellerImageView.isUserInteractionEnabled = true
		sellerImageView.addGestureRecognizer(tapGestureRecognizer)

		let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(showSellerCloset))
		sellerNameLabel.isUserInteractionEnabled = true
		sellerNameLabel.addGestureRecognizer(tapGestureRecognizer2)
    }

	fileprivate func renderListing() {
		Nuke.loadImage(
			with: Utilities.getUrlForUserPicture(userId: listing._sellerId!),
			options: ImageLoadingOptions(
				placeholder: #imageLiteral(resourceName: "placeholder"),
				transition: .fadeIn(duration: 0.33)
			),
			into: sellerImageView
		)
		DB.shared().getUser(with: listing._sellerId!)
		update()
	}

	fileprivate func renderSeller() {
		sellerNameLabel.text = seller!._name!
		if gblUser._id! != listing._sellerId! {
			messageButton.setTitle("Message \(seller!._name!)", for: UIControlState())
		}
	}

	@objc fileprivate func showSellerCloset() {
		if let user = seller {
			let vc = Utilities.getClosetVcFor(user: user)
			self.navigationController?.pushViewController(vc, animated: true)
		}
	}

	func update() {
		for sub in imageContainerView.subviews {
			sub.removeFromSuperview()
		}

		imageContainerHeightConstraint.constant = CGFloat(listing._imageCount!.intValue) * (imageContainerView.frame.width + imagePadding)

		listingNameLabel.text = listing._name ?? ".."
		let price = listing._price == nil ? 0 : listing._price!.intValue
		for label in listingPriceLabels {
			label.text = "$\(price)"
		}
		let originalPrice = listing._originalPrice == nil ? 0 : listing._originalPrice!.intValue
		let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "$\(originalPrice)")
		attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue), range: NSMakeRange(0, attributeString.length))
		for label in originalPriceLabels {
			label.attributedText = attributeString
		}
		sizeLabel.text = "Size: \(listing._size ?? "..")"
		descriptionTextView.text = listing._description ?? ".."
		categoryLabel.text = listing!._category ?? ".."

		images = []
		loadImage(index: 2)
		textViewHeightConstraint.constant = descriptionTextView.contentSize.height
		self.view.layoutIfNeeded()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		DB.shared().delegate = self
	}

	@objc fileprivate func editPressed() {
		if isLoadingImages {
			singleActionPopup(title: "Please wait", message: "Images must finish loading before you edit this listing.")
			return
		}
		SVProgressHUD.show(withStatus: "Confirming with server...")
		wantToEdit = true
		checkIfRentedOut()
	}

	fileprivate func edit() {
		performSegue(withIdentifier: "toEditListing", sender: nil)
	}

	@objc fileprivate func deletePressed() {
		wantToDelete = true
		SVProgressHUD.show(withStatus: "Confirming with server...")
		checkIfRentedOut()
	}

	fileprivate func checkIfRentedOut() {
		DB.shared().getRentalForListing(withId: listing._id!)
	}

	fileprivate func delete() {
		popupAlert(title: "Are you sure you want to delete your listing?", message: "This action cannot be undone.", actionTitles: ["Delete", "Cancel"], actions: [{ (action) in
			DB.shared().deleteListing(self.listing)
			}, nil])
	}


	fileprivate func addImage(_ image : UIImage) {
		images.append(image)

		let index = CGFloat(imageContainerView.subviews.count)
		let height = imageContainerView.frame.size.width
		let width = imageContainerView.frame.size.width

		let imageView = UIImageView()
		imageView.image = image
		imageView.frame = CGRect(x: 0, y: index * (height + imagePadding), width: width, height: height)

		imageContainerView.addSubview(imageView)
	}

	fileprivate func loadImage(index : Int) {
		isLoadingImages = true
		let fileName = "listing-images/\(listing._id!)-\(index)" // CHANGED CODE
		let expression = AWSS3TransferUtilityDownloadExpression()
		expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
			print(progress.fractionCompleted)
		})
		}

		var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
		completionHandler = { (task, URL, data, error) -> Void in
			DispatchQueue.main.async(execute: {
				if error != nil {
					print(error)
				} else {
					print("download complete")
					self.addImage(UIImage(data: data!)!) // CHANGED CODE
					if index <= self.listing._imageCount!.intValue {
						self.loadImage(index: index + 1)
					} else {
						self.isLoadingImages = false
					}
				}
			})
		}

		let transferUtility = AWSS3TransferUtility.default()

		transferUtility.downloadData(
			forKey: fileName,
			expression: expression,
			completionHandler: completionHandler
			).continueWith {
				(task) -> AnyObject? in if let error = task.error {
					print("Error: \(error.localizedDescription)")
				}

				if let _ = task.result {
					// Do something with downloadTask.
					print(task.result)

				}
				return nil;
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	fileprivate func rentOut() {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "HandoffVC") as! HandoffViewController
		vc.config = .pickup
		vc.listing = listing
		self.present(vc, animated: true, completion: nil)
	}

	@IBAction func messageOwner(_ sender: Any) {
		if gblUser._id! == listing._sellerId! { // this is my listing
			SVProgressHUD.show(withStatus: "Confirming with server...")
			wantToRentOut = true
			checkIfRentedOut()
			return
		}
		SVProgressHUD.show(withStatus: "Creating conversation...")
		let userIds = [gblUser._id!, listing._sellerId!]
		SBDGroupChannel.createChannel(withName: listing._name, userIds: userIds, coverUrl: Utilities.getUrlForListingPicture(listingId: listing._id!, imageNumber: 1).absoluteString, data: nil) { (channel, error) in
			if error != nil {
				SVProgressHUD.dismiss()
				self.singleActionPopup(title: "Failed to create conversation", message: "Please try again soon.")
				NSLog("Error: %@", error!)
				return
			}
			self.createdChannel = channel!
			let convo = Conversation()!
			convo._channelUrl = channel!.channelUrl
			convo._listingId = self.listing._id!
			convo._purchaserId = gblUser._id!
			convo._sellerId = self.listing._sellerId!
			DB.shared().createConversation(convo: convo)
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "toEditListing" {
			if let vc = segue.destination as? CreateListingViewController {
				vc.isEditView = true
				vc.initialImages = self.images
				vc.newListing = self.listing
				vc.parentVC = self
			}
		}
	}
}

extension ListingDetailsViewController : DBDelegate {
	func deleteListingResponse(success: Bool) {
		if success {
			self.navigationController?.popViewController(animated: true)
		} else {
			singleActionPopup(title: "Failed to delete your listing.", message: "Please try again later.")
		}
	}

	func getUserResponse(success: Bool, user: User?, error: String?) {
		if success {
			seller = user
			renderSeller()
		} else {
			singleActionPopup(title: "Failed to load seller information.", message: "Please try this listing again later.") { (action) in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}

	func getListingResponse(success: Bool, listing: Listing?, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			self.listing = listing!
			renderListing()
		} else {
			singleActionPopup(title: "Failed to fetch listing details.", message: "Please try entering this page again.") { (action) in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}

	func createConversationResponse(success: Bool, error: String?) {
		SVProgressHUD.dismiss()
		let vc = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: Bundle.main)
		vc.groupChannel = createdChannel

		self.present(vc, animated: true, completion: nil)
	}

	func getRentalForListingResponse(success: Bool, rental: Rental?, error: String?) {
		SVProgressHUD.dismiss()
		if success {
			if rental == nil {
				if wantToDelete {
					delete()
				} else if wantToEdit {
					edit()
				} else if wantToRentOut {
					rentOut()
				}
			} else {
				if wantToRentOut {
					singleActionPopup(title: "This item is already rented out.", message: "Navigate to 'My Rentals' if you would like to accept this item's return")
				} else {
					singleActionPopup(title: "You cannot modify this listing while it is on rent", message: "Please wait until this listing is returned to make any changes.")
				}
			}
		} else {
			singleActionPopup(title: "Failed to contact server", message: "Please try again later.")
		}
		wantToDelete = false
		wantToEdit = false
		wantToRentOut = false
	}
}
