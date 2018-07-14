//
//  AppDelegate.swift
//  StyleRent
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import UIKit
import AWSMobileClient
import FBSDKCoreKit
import Stripe
import SendBirdSDK


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
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
		STPPaymentConfiguration.shared().publishableKey = "pk_test_O7WymMY05Cpb7FIInhdDyFHL"
		// TODO: Set up Apple pay through apple developer website
		//STPPaymentConfiguration.shared().appleMerchantIdentifier = "your apple merchant identifier"
		return AWSMobileClient.sharedInstance().interceptApplication(
			application,
			didFinishLaunchingWithOptions: launchOptions)
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
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

