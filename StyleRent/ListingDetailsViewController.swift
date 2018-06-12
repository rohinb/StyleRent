//
//  ListingDetailsController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 6/11/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSS3

class ListingDetailsViewController: UIViewController {
	@IBOutlet weak var scrollView: UIScrollView!
	var listing : Listing!

    override func viewDidLoad() {
        super.viewDidLoad()
		scrollView.isPagingEnabled = true
		scrollView.contentSize = CGSize(width: Double(scrollView.frame.size.height) * Double(listing._imageCount!.intValue - 1), height: Double(scrollView.frame.size.height))
		
		loadImage(index: 2)
    }

	func addImage(_ image : UIImage) {
		let index = CGFloat(scrollView.subviews.count)
		let height = scrollView.frame.size.height
		let width = scrollView.frame.size.width

		let imageView = UIImageView()
		imageView.image = image
		imageView.frame = CGRect(x: (index - 1) * width, y: 0, width: width, height: height)

		scrollView.addSubview(imageView)
		scrollView.flashScrollIndicators()
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

}
