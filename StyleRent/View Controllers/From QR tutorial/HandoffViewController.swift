//
//  HandoffViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/27/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit

enum HandoffType : String {
	case pickup = "pickup"
	case dropoff = "dropoff"
}
class HandoffViewController: UIViewController {
	@IBOutlet weak var qrImageView: UIImageView!

	var config : HandoffType!
	var listing : Listing!
	var rental : Rental!

    override func viewDidLoad() {
        super.viewDidLoad()
		let dict = ["type" : config.rawValue, "id" : rental._id ?? listing._id!]

		let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)

		let filter = CIFilter(name: "CIQRCodeGenerator")!

		filter.setValue(data, forKey: "inputMessage")
		filter.setValue("Q", forKey: "inputCorrectionLevel")

		let qrcodeImage = filter.outputImage!

		let scaleX = qrImageView.frame.size.width / qrcodeImage.extent.size.width
		let scaleY = qrImageView.frame.size.height / qrcodeImage.extent.size.height

		let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

		qrImageView.image = UIImage(ciImage: transformedImage)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	@IBAction func dismiss(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}


}
