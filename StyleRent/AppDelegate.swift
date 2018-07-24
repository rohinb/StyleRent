//
//  AppDelegate.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSMobileClient
import AWSCognito
import FBSDKCoreKit
import Stripe
import SendBirdSDK
import AWSSNS
import AWSCore
import AWSPinpoint
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?
	var pinpoint: AWSPinpoint?
	let SNSPlatformApplicationArn = "arn:aws:sns:us-east-1:235814408369:app/APNS_SANDBOX/StyleRent"

	static let instance: NSCache<AnyObject, AnyObject> = NSCache()

	static func imageCache() -> NSCache<AnyObject, AnyObject>! {
		if AppDelegate.instance.totalCostLimit == 104857600 {
			AppDelegate.instance.totalCostLimit = 104857600
		}

		return AppDelegate.instance
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		SBDMain.initWithApplicationId("64DBE184-31A5-421E-BC58-CA2E3A34E5D5")
		let config = STPPaymentConfiguration.shared()
		config.publishableKey = "pk_test_O7WymMY05Cpb7FIInhdDyFHL"
		config.companyName = "Style Rent"
		// Create card sources instead of card tokens
		config.createCardSources = true;
		config.requiredBillingAddressFields = .zip
		config.requiredShippingAddressFields = []
		config.additionalPaymentMethods = .all
		STPPaymentConfiguration.shared().appleMerchantIdentifier = "merchant.StyleRent"

		let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
																identityPoolId:"us-east-1:1e730877-8ae1-42c1-990c-310863a4e5f2")

		let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)

		AWSServiceManager.default().defaultServiceConfiguration = configuration

		pinpoint =
			AWSPinpoint(configuration:
				AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: launchOptions))

		logEvent()
		sendMonetizationEvent()
		registerForPushNotifications(application: application)
		return AWSMobileClient.sharedInstance().interceptApplication(
			application,
			didFinishLaunchingWithOptions: launchOptions)
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
	}

	func application(
		_ application: UIApplication,
		didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

		/// Attach the device token to the user defaults
		var token = ""
		for i in 0..<deviceToken.count {
			token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
		}
		print(token)
		Defaults.standard.set(token, forKey: Defaults.deviceTokenKey)

		SBDMain.registerDevicePushToken(deviceToken, unique: true) { (status, error) in
			if error == nil {
				if status == SBDPushTokenRegistrationStatus.pending {
					print("Pending registration with send bird")
				}
				else {
					print("Succeeded registration with send bird")
				}
			}
			else {
				print("Failed registration with send bird")
			}
		}

		/// Create a platform endpoint
		let sns = AWSSNS.default()
		let request = AWSSNSCreatePlatformEndpointInput()
		request?.token = token
		request?.customUserData = gblUser?._id!
		request?.platformApplicationArn = SNSPlatformApplicationArn
		sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
			if task.error != nil {
				print("Error: \(String(describing: task.error))")
			} else {
				let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
				if let endpointArnForSNS = createEndpointResponse.endpointArn {
					print("endpointArn: \(endpointArnForSNS)")
					Defaults.standard.set(endpointArnForSNS, forKey: Defaults.pushEndpointKey)
					if let user = gblUser {
						user._pushEndpoint = endpointArnForSNS
						DB.shared().updateUser(user)
					}
				}
			}
			return nil
		})
		pinpoint!.notificationManager.interceptDidRegisterForRemoteNotifications(
			withDeviceToken: deviceToken)
	}

	// Called when a notification is delivered to a foreground app.
	@available(iOS 10.0, *)
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		print("User Info = ",notification.request.content.userInfo)
		completionHandler([.alert, .badge, .sound])
	}
	// Called to let your app know which action was selected by the user for a given notification.
	@available(iOS 10.0, *)
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		print("User Info = ",response.notification.request.content.userInfo)
		completionHandler()
	}

	func registerForPushNotifications(application: UIApplication) {
		/// The notifications settings
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().delegate = self
			UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
				if (granted)
				{
					DispatchQueue.main.async {
						UIApplication.shared.registerForRemoteNotifications()
					}
				}
				else{
					print("User denied access to push notifications.")
				}
			})
		} else {
			let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
			application.registerUserNotificationSettings(settings)
			application.registerForRemoteNotifications()
		}
	}

	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error.localizedDescription)
	}

	// TODO: Move event logging into its own class and actually implement
	func logEvent() {

		let pinpointAnalyticsClient =
			AWSPinpoint(configuration:
				AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: nil)).analyticsClient

		let event = pinpointAnalyticsClient.createEvent(withEventType: "TestEvent")
		event.addAttribute("DemoAttributeValue1", forKey: "DemoAttribute1")
		event.addAttribute("DemoAttributeValue2", forKey: "DemoAttribute2")
		event.addMetric(NSNumber.init(value: arc4random() % 65535), forKey: "RandomMetric")
		pinpointAnalyticsClient.record(event)
		pinpointAnalyticsClient.submitEvents()

	}

	// TODO: Move revenue logging into its own class and actually implement
	func sendMonetizationEvent()
	{
		let pinpointClient = AWSPinpoint(configuration:
			AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: nil))

		let pinpointAnalyticsClient = pinpointClient.analyticsClient

		let event =
			pinpointAnalyticsClient.createVirtualMonetizationEvent(withProductId:
				"DEMO_PRODUCT_ID", withItemPrice: 1.00, withQuantity: 1, withCurrency: "USD")
		pinpointAnalyticsClient.record(event)
		pinpointAnalyticsClient.submitEvents()
	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		print("got notification bruh")
	}

	func application(
		_ application: UIApplication,
		didReceiveRemoteNotification userInfo: [AnyHashable: Any],
		fetchCompletionHandler completionHandler:
		@escaping (UIBackgroundFetchResult) -> Void) {

		pinpoint!.notificationManager.interceptDidReceiveRemoteNotification(
			userInfo, fetchCompletionHandler: completionHandler)

		if (application.applicationState == .active) {
			let alert = UIAlertController(title: "Notification Received",
										  message: userInfo.description,
										  preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

			UIApplication.shared.keyWindow?.rootViewController?.present(
				alert, animated: true, completion:nil)
		}
	}

	func application(_ application: UIApplication, open url: URL,
					 sourceApplication: String?, annotation: Any) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		FBSDKAppEvents.activateApp()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

