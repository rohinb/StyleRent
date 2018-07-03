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

class ListingDetailsViewController: UIViewController {
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
	@IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!

	let imagePadding = CGFloat(20)

	var listing : Listing!

    override func viewDidLoad() {
        super.viewDidLoad()
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

		textViewHeightConstraint.constant = descriptionTextView.contentSize.height
		self.view.layoutIfNeeded()

		loadImage(index: 2)
    }

	func addImage(_ image : UIImage) {
		let index = CGFloat(imageContainerView.subviews.count)
		let height = imageContainerView.frame.size.width
		let width = imageContainerView.frame.size.width

		let imageView = UIImageView()
		imageView.image = image
		imageView.frame = CGRect(x: 0, y: index * (height + imagePadding), width: width, height: height)

		imageContainerView.addSubview(imageView)
	}

	fileprivate func loadImage(index : Int) {
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
					print("downlaod complete")
					self.addImage(UIImage(data: data!)!) // CHANGED CODE
					if index <= self.listing._imageCount!.intValue {
						self.loadImage(index: index + 1)
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

	@IBAction func messageOwner(_ sender: Any) {
		let userIds = [gblUserId!, listing._sellerId!]
		//SBDGroupChannel.createChannel(withName: <#T##String?#>, isDistinct: <#T##Bool#>, users: <#T##[SBDUser]#>, coverUrl: <#T##String?#>, data: <#T##String?#>, completionHandler: <#T##(SBDGroupChannel?, SBDError?) -> Void#>)
		SBDGroupChannel.createChannel(withUserIds: userIds, isDistinct: true) { (channel, error) in
			if error != nil {
				NSLog("Error: %@", error!)
				return
			}
			channel?.name = "Listing Chat"
			let vc = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: Bundle.main)
			vc.groupChannel = channel

			self.present(vc, animated: true, completion: nil)
			print("Channel created!")
		}
	}
}
