//
//  SPFile.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 18.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class SPFile: NSObject {
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
}

extension SPFile {
    public func updateFileExtension(fileExtension: String) {
        self.fileExtension = fileExtension
    }
    
    public func updateSiteUrl(fileUrl: String) {
        self.fileUrl = fileUrl
    }
}
