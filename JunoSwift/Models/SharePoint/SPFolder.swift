//
//  SPFolder.swift
//  Juno
//
//  Created by Uğur Uğurlu on 18.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class SPFolder: NSObject {
    public var name: String?
    public var serverRelativeUrl: String?
    public var createdDate: String?
    public var lastModifiedDate: String?
    public var uniqueId: String?
    public var itemCount: Int?
    public var url: String?
    public var editLink: String?
    public var progId: String?
    public var coverPhoto: String?
    public var albumDate: String?
    public var id: Int?
    
    public init(dict: NSDictionary) {
        self.name = dict["Name"] as? String
        self.serverRelativeUrl = dict["ServerRelativeUrl"] as? String
        self.createdDate = dict["TimeCreated"] as? String
        self.lastModifiedDate = dict["TimeLastModified"] as? String
        self.uniqueId = dict["UniqueId"] as? String
        self.itemCount = dict["ItemCount"] as? Int
        self.url = dict["odata.id"] as? String
        self.editLink = dict["odata.editLink"] as? String
        self.progId = dict["ProgID"] as? String
        self.albumDate = dict["AlbumDate"] as? String
        self.id = dict["ID"] as? Int
    }
}

extension SPFolder {
    public func updateCoverPhoto(fileName: String) {
        self.coverPhoto = fileName
    }
}
