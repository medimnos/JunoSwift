//
//  SPListItem.swift
//  Juno
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class SPListItem: NSObject {
    public var id: Int = 0
    private(set) var url: String = ""
    public var listName: String = ""
    public var dictionary: NSDictionary?
    public var attachmentFiles = [SPAttachment]()
    public var delegate: AttachmentActionDelegate?
    private(set) var subSite: String = ""
    private(set) var fieldValuesAsHtml: Bool = false
    public var withId: Bool = false
    
    public init(id: Int = 0, listName: String, fieldValuesAsHtml: Bool = false, dictionary: NSDictionary?, withId: Bool = false) {
        super.init()
        
        self.listName = listName
        self.id = id
        self.fieldValuesAsHtml = fieldValuesAsHtml
        self.withId = withId
        
        if withId {
            self.url = "Lists/GetById('\(self.listName)')/Items"
            self.updateItem()
        }else {
            self.updateListUrl()
        }
        
        if let _dictionary = dictionary {
            self.dictionary = _dictionary
            
            if let _id = _dictionary["ID"] as? Int {
                self.id = _id
            }
            
            if let attachmentFiles = _dictionary["AttachmentFiles"] as? NSArray {
                for item in attachmentFiles {
                    if let dict = item as? NSDictionary {
                        let attachment = SPAttachment()
                        if let fileName = dict["FileName"] as? String {
                            attachment.fileName = fileName
                        }
                        if let filePath = dict["ServerRelativeUrl"] as? String {
                            attachment.filePath = filePath
                        }
                        self.attachmentFiles.append(attachment)
                    }
                }
            }
        }
    }
}

public extension SPListItem {
    
    //check whether itemId greater then 0
    func isNew()-> Bool{
        var status: Bool = false
        if self.id == 0 {
            status = true
        }
        return status
    }
    
    //save || update SPListItem
    //@completionHandler: (SPListItem)
    //method access: public
    func save(completionHandler: @escaping SPListItemHandler){
        SharePoint.shared.saveListItem(item: self, completionHandler: completionHandler)
    }
    
    //save attachment to SPListItem
    //@completionHandler: (Attachment)
    //method access: public
    func addAttachment(){
        self.uploadFile(itemUrl: self.url, attachmentList: self.attachmentFiles, uploadingFileIndex: 0)
    }
    
    //method access: private
    private func uploadFile(itemUrl: String, attachmentList: [SPAttachment], uploadingFileIndex: Int){
        
        let fileCount = attachmentList.count
        var currentIndex = uploadingFileIndex
        
        //check file index exist
        let validIndex = attachmentList.indices.contains(currentIndex)
        if validIndex {
            let attachment = attachmentList[currentIndex]
            self.delegate?.attachmentActionProgress!(uploadedFileCount: currentIndex, totalFileCount: fileCount)
            
            if let fileData = attachment.data {
                SharePoint.shared.uploadAttachment(itemUrl: itemUrl, file: fileData, completionHandler: { (uploadedAttachment) in
                    self.delegate?.attachmentActionProgressDone!(attachment: uploadedAttachment, uploadedFileCount: currentIndex)
                    currentIndex += 1
                    if currentIndex < fileCount {
                        self.uploadFile(itemUrl: itemUrl, attachmentList: attachmentList, uploadingFileIndex: currentIndex)
                    }else {
                        self.delegate?.attachmentUploadFinished!()
                    }
                })
            }
        }
    }
    
    func updateSubSite(subSite: String, listPrefix: String = "/Lists") {
        self.subSite = subSite
        
        self.updateListUrl(listPrefix: listPrefix)
    }
    
    private func updateListUrl(listPrefix: String = "/Lists") {
        let siteName = SharePoint.shared.getSiteName()
        self.url = "GetList('\(siteName)\(self.subSite != "" ? "/\(self.subSite)" : "")\(listPrefix)/\(self.listName)')/Items"
        
        self.updateItem()
    }
    
    func updateItem() {
        if !self.isNew() {
            self.url += "('\(self.id)')"
        }
        
        if self.fieldValuesAsHtml {
            self.url += "/FieldValuesAsHtml"
        }
    }
}

