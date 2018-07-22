//
//  CheckoutViewController.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 7/14/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.

import UIKit
import Stripe

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {
	let paymentCurrency = "usd"

	let paymentContext: STPPaymentContext

	fileprivate let theme: STPTheme
	fileprivate let paymentRow: CheckoutRowView
	fileprivate let shippingRow: CheckoutRowView
	fileprivate let totalRow: CheckoutRowView
	fileprivate let buyButton: BuyButton
	fileprivate let rowHeight: CGFloat = 44
	fileprivate let productImage = UILabel()
	fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
	fileprivate let numberFormatter: NumberFormatter
	fileprivate let shippingString: String

	var listing : Listing!
	var confirmVc : RentalViewController?
	var paymentInProgress: Bool = false {
		didSet {
			UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
				if self.paymentInProgress {
					self.activityIndicator.startAnimating()
					self.activityIndicator.alpha = 1
					self.buyButton.alpha = 0
				}
				else {
					self.activityIndicator.stopAnimating()
					self.activityIndicator.alpha = 0
					self.buyButton.alpha = 1
				}
			}, completion: nil)
		}
	}

	init(listing: Listing, price: Int) {
		self.listing = listing
		self.theme = STPTheme.default()
		let config = STPPaymentConfiguration.shared()

		let customerContext = STPCustomerContext(keyProvider: API.shared)
		let paymentContext = STPPaymentContext(customerContext: customerContext,
											   configuration: STPPaymentConfiguration.shared(),
											   theme: self.theme)
		let userInformation = STPUserInformation()
		paymentContext.prefilledInformation = userInformation
		paymentContext.paymentAmount = price
		paymentContext.paymentCurrency = self.paymentCurrency

		let addCardFooter = PaymentContextFooterView(text: "Style Rent uses Stripe for all payments and credit card information. Style Rent not store any of your credit card information.")
		addCardFooter.theme = self.theme
		paymentContext.addCardViewControllerFooterView = addCardFooter

		self.paymentContext = paymentContext

		self.paymentRow = CheckoutRowView(title: "Payment", detail: "Select Payment",
										  theme: self.theme)
		var shippingString = "Contact"
		if config.requiredShippingAddressFields?.contains(.postalAddress) ?? false {
			shippingString = config.shippingType == .shipping ? "Shipping" : "Delivery"
		}
		self.shippingString = shippingString
		self.shippingRow = CheckoutRowView(title: self.shippingString,
										   detail: "Enter \(self.shippingString) Info",
			theme: self.theme)
		self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false,
										theme: self.theme)
		self.buyButton = BuyButton(enabled: true, theme: self.theme)
		var localeComponents: [String: String] = [
			NSLocale.Key.currencyCode.rawValue: self.paymentCurrency,
			]
		localeComponents[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first
		let localeID = NSLocale.localeIdentifier(fromComponents: localeComponents)
		let numberFormatter = NumberFormatter()
		numberFormatter.locale = Locale(identifier: localeID)
		numberFormatter.numberStyle = .currency
		numberFormatter.usesGroupingSeparator = true
		self.numberFormatter = numberFormatter
		super.init(nibName: nil, bundle: nil)
		self.paymentContext.delegate = self
		paymentContext.hostViewController = self
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		DB.shared().delegate = self
		self.view.backgroundColor = self.theme.primaryBackgroundColor
		var red: CGFloat = 0
		self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
		self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .white : .gray
		self.navigationItem.title = "Emoji Apparel"

		self.productImage.font = UIFont.systemFont(ofSize: 70)
		self.view.addSubview(self.totalRow)
		self.view.addSubview(self.paymentRow)
		//self.view.addSubview(self.shippingRow)
		self.view.addSubview(self.productImage)
		self.view.addSubview(self.buyButton)
		self.view.addSubview(self.activityIndicator)
		self.activityIndicator.alpha = 0
		self.buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
		self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
		self.paymentRow.onTap = { [weak self] in
			self?.paymentContext.presentPaymentMethodsViewController()
		}
		self.shippingRow.onTap = { [weak self]  in
			self?.paymentContext.presentShippingViewController()
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		var insets = UIEdgeInsets.zero
		if #available(iOS 11.0, *) {
			insets = view.safeAreaInsets
		}
		let width = self.view.bounds.width - (insets.left + insets.right)
		self.productImage.sizeToFit()
		self.productImage.center = CGPoint(x: width/2.0,
										   y: self.productImage.bounds.height/2.0 + rowHeight)
		self.paymentRow.frame = CGRect(x: insets.left, y: self.productImage.frame.maxY + rowHeight,
									   width: width, height: rowHeight)
		self.shippingRow.frame = CGRect(x: insets.left, y: self.paymentRow.frame.maxY,
										width: width, height: rowHeight)
		self.totalRow.frame = CGRect(x: insets.left, y: self.shippingRow.frame.maxY,
									 width: width, height: rowHeight)
		self.buyButton.frame = CGRect(x: insets.left, y: 0, width: 88, height: 44)
		self.buyButton.center = CGPoint(x: width/2.0, y: self.totalRow.frame.maxY + rowHeight*1.5)
		self.activityIndicator.center = self.buyButton.center
	}

	fileprivate func paymentSuccess() {
		let rental = Rental()!
		rental._id = UUID().uuidString
		rental._borrowerId = gblUser._id!
		rental._isActive = NSNumber(booleanLiteral: true)
		rental._lenderId = listing._sellerId!
		rental._listingId = listing._id!
		rental._price = listing._price! //save the agreed upon price
		let startDate = Date()
		// TODO: Edit rental period, rn it's always 4 days
		let endDate = startDate.addingTimeInterval(4 * 60 * 60 * 24)
		rental._startDate = Utilities.getApiDateFor(date: startDate)
		rental._returnDate = Utilities.getApiDateFor(date: endDate)

		DB.shared().createRental(rental: rental)
	}

	@objc fileprivate func didTapBuy() {
		self.paymentInProgress = true
		self.paymentContext.requestPayment()
	}

	// MARK: STPPaymentContextDelegate

	func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
		API.shared.completeCharge(paymentResult,
												amount: self.paymentContext.paymentAmount,
												shippingAddress: self.paymentContext.shippingAddress,
												shippingMethod: self.paymentContext.selectedShippingMethod,
												completion: completion)
	}

	func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
		switch status {
		case .error:
			self.paymentInProgress = false
			let message = error?.localizedDescription ?? ""
			print("Error: \(message)")
			singleActionPopup(title: "Payment failed to go through.", message: "Please ensure that you are connected to the internet and try again. If problem persists, contact customer service. Tell them about this error: \(message)")
		case .success:
			paymentSuccess()
		case .userCancellation:
			break
		}
	}

	func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
		self.paymentRow.loading = paymentContext.loading
		if let paymentMethod = paymentContext.selectedPaymentMethod {
			self.paymentRow.detail = paymentMethod.label
		}
		else {
			self.paymentRow.detail = "Select Payment"
		}
		if let shippingMethod = paymentContext.selectedShippingMethod {
			self.shippingRow.detail = shippingMethod.label
		}
		else {
			self.shippingRow.detail = "Enter \(self.shippingString) Info"
		}
		self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
	}

	func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
		let alertController = UIAlertController(
			title: "Error",
			message: error.localizedDescription,
			preferredStyle: .alert
		)
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
			// Need to assign to _ because optional binding loses @discardableResult value
			// https://bugs.swift.org/browse/SR-1681
			_ = self.navigationController?.popViewController(animated: true)
		})
		let retry = UIAlertAction(title: "Retry", style: .default, handler: { action in
			self.paymentContext.retryLoading()
		})
		alertController.addAction(cancel)
		alertController.addAction(retry)
		self.present(alertController, animated: true, completion: nil)
	}

}

extension CheckoutViewController : DBDelegate {
	func createRentalResponse(success: Bool, error: String?) {
		self.paymentInProgress = false
		if success {
			singleActionPopup(title: "Payment is complete and rental has successfully initiated.", message: "Instruct the lender to hand over the listing item to you and the transaction is complete.") { (action) in
				self.dismiss(animated: true) {
					self.confirmVc?.dismiss(animated: true, completion: nil)
				}
			}
		} else {
			singleActionPopup(title: "Rental creation failed.", message: "//TODO: handle")
		}
	}
}
