//
//  SPList.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 14.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class SPList: NSObject {
    public var listName: String = ""
    public var listItems = [SPListItem]()
    public var nextPage: String = ""
    public var defaultListType: String = ""
    private(set) var listUrl: String = ""
    private(set) var subSite: String = ""
    public var withId: Bool = false
    
    public init(listName: String, defaultListType: String = "Items", withId: Bool = false) {
        super.init()
        
        self.listName = listName
        self.defaultListType = defaultListType
        self.withId = withId
        
        if withId {
            self.listUrl = "Lists/GetById('\(self.listName)')/\(self.defaultListType)"
        }else {
            self.updateListUrl()
        }
    }
}

extension SPList {
    
    func updateSubSite(subSite: String, listPrefix: String) {
        self.subSite = subSite
        
        self.updateListUrl(listPrefix: listPrefix)
    }
    
    private func updateListUrl(listPrefix: String = "/Lists") {
        let siteName = SharePoint.shared.getSiteName()
        self.listUrl = "GetList('\(siteName)\(self.subSite != "" ? "/\(self.subSite)" : "")\(listPrefix)/\(self.listName)')/\(self.defaultListType)"
    }
}
