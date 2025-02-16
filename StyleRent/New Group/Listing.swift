//
//  Listings.swift
//  MySampleApp
//
//
// Copyright 2018 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.21
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers
class Listing: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _id: String?
    var _description: String?
    var _latitude: NSNumber?
    var _longitude: NSNumber?
	var _blockId: String?
    var _name: String?
    var _price: NSNumber?
	var _originalPrice: NSNumber?
	var _imageCount: NSNumber?
    var _sellerId: String?
    var _size: String?
    var _category: String?
    
    class func dynamoDBTableName() -> String {

        return "stylerentbackend-mobilehub-1070684980-Listings"
    }
    
    class func hashKeyAttribute() -> String {

        return "_id"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_id" : "id",
               "_description" : "description",
               "_latitude" : "latitude",
               "_longitude" : "longitude",
               "_name" : "name",
               "_price" : "price",
			   "_imageCount" : "imageCount",
			   "_originalPrice" : "originalPrice",
               "_sellerId" : "sellerId",
               "_size" : "size",
               "_category" : "category",
			   "_blockId" : "blockId"
        ]
    }
}
