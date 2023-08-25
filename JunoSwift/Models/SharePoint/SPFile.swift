//
//  SPFile.swift
//  Juno
//
//  Created by Uğur Uğurlu on 18.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class SPFile: NSObject, NSSecureCoding {
    public var size: String?
    public var name: String?
    public var serverRelativeUrl: String?
    public var title: String?
    public var uniqueId: String?
    public var createdDate: String?
    public var lastModifiedDate: String?
    public var fileUrl: String?
    public var fileExtension: String = ""
    public var id: String?
    
    public init(dict: NSDictionary) {
        self.size = dict["Length"] as? String
        self.name = dict["Name"] as? String
        self.serverRelativeUrl = dict["ServerRelativeUrl"] as? String
        self.title = dict["Title"] as? String
        self.uniqueId = dict["UniqueId"] as? String
        self.createdDate = dict["TimeCreated"] as? String
        self.lastModifiedDate = dict["TimeLastModified"] as? String
        self.fileUrl = dict["odata.id"] as? String
        self.id = dict["ListItemID"] as? String
        if let fileName = self.name {
            self.fileExtension = URL(fileURLWithPath: fileName).pathExtension
        }
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.size = aDecoder.decodeObject(forKey: "size") as? String
        self.name = aDecoder.decodeObject(forKey: "name") as? String
        self.serverRelativeUrl = aDecoder.decodeObject(forKey: "serverRelativeUrl") as? String
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.uniqueId = aDecoder.decodeObject(forKey: "uniqueId") as? String
        self.createdDate = aDecoder.decodeObject(forKey: "createdDate") as? String
        self.lastModifiedDate = aDecoder.decodeObject(forKey: "lastModifiedDate") as? String
        self.fileUrl = aDecoder.decodeObject(forKey: "fileUrl") as? String
        self.id = aDecoder.decodeObject(forKey: "id") as? String
        self.fileExtension = aDecoder.decodeObject(forKey: "fileExtension") as? String ?? ""
        
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(serverRelativeUrl, forKey: "serverRelativeUrl")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(createdDate, forKey: "createdDate")
        aCoder.encode(lastModifiedDate, forKey: "lastModifiedDate")
        aCoder.encode(fileUrl, forKey: "fileUrl")
        aCoder.encode(fileExtension, forKey: "fileExtension")
    }
}

extension SPFile {
    public func updateFileExtension(fileExtension: String) {
        self.fileExtension = fileExtension
    }
    
    public func updateSiteUrl(fileUrl: String) {
        self.fileUrl = fileUrl
    }
}
