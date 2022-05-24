//
//  SharePoint.swift
//  Juno
//
//  Created by Uğur Uğurlu on 10.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import Alamofire

//SPListItem typealias
public typealias SPListItemHandler = (_ success: SPListItem, _ error: NSDictionary?)->()

//SPList typealias
public typealias SPListHandler = (_ success: SPList, _ error: NSDictionary?)->()

//SPList Array typealias
public typealias SPListArrayHandler = (_ success: [SPList], _ error: NSDictionary?)->()

//SPFolder SPFile typealias
public typealias SPDocumentHandler = (_ success: ([SPFolder], [SPFile]), _ error: NSDictionary?)->()

public class SharePoint {
    
    //create singleton instance
    public static var shared = SharePoint()
    
    private init(){}
    
    //list prefix
    public var listPrefix = "/_api/web/"
    private var siteUrl: String = ""
    
    //site name
    private var siteName: String?
    
    //update sharepoint site url
    //params: siteUrl (String)
    //completionHandler: (Void)
    //method access: public
    public func updateSiteUrl(siteUrl: String) {
        JunoConfig.resources[.SharePoint] = siteUrl as AnyObject
        self.siteUrl = siteUrl
    }
    
    public func updateSiteName(siteName: String) {
        self.siteName = siteName
        self.listPrefix = "\(siteName)/_api/web/"
    }
    
    public func getSiteName() -> String {
        var str = ""
        if let _siteName = self.siteName {
            str = _siteName
        }
        
        return str
    }
    
    //get form digest value
    //completionHandler: (String)
    //method access: private
    func getFormDigestValue(completionHandler: @escaping(String)->()){
        Connection.shared.request(method: .post, resource: .SharePoint, endPoint: "\(JunoConfig.resources[.SharePoint] as! String)/_api/contextinfo") { (success, error) in
            var formDigestValue: String = ""
            if let dict = success {
                if let digest = dict["FormDigestValue"] as? String {
                    formDigestValue = digest
                }
            }
            completionHandler(formDigestValue)
        }
    }
    
    //get list properties
    //@completionHandler: (String)
    //method access: private
    func getListProperties(listName: String, completionHandler: @escaping(String)->()){
        let url: String = "\(self.listPrefix)GetByTitle('\(listName)')"
        
        Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
            var listItemEntityTypeFullName: String = ""
            if error == nil {
                if let entityType = success?.value(forKeyPath: "ListItemEntityTypeFullName") as? String {
                    listItemEntityTypeFullName = entityType
                }
            }
            completionHandler(listItemEntityTypeFullName)
        }
    }
    
    //get sharepoint list items
    //@params: listName: String
    //completionHandler: ([SpListItem])
    //type: GET
    //method access: public
    public func getListItems(list: SPList, withQuery: [String: AnyObject]?, nextPage: String = "", camlQuery: String = "", subSite: String = "", listPrefix: String = "/Lists", completionHandler: @escaping SPListHandler){
        
        if !list.withId {
            list.updateSubSite(subSite: subSite, listPrefix: listPrefix)
        }
        
        var url: String = "\(self.listPrefix)\(list.listUrl)"
        
        if subSite != "" {
            if let _siteName = self.siteName {
                url = "\(_siteName)/\(subSite)/_api/web/\(list.listUrl)"
            }
        }
        
        var method: HTTPMethod = .get
        var parameters = [String: AnyObject]()
        
        if camlQuery != "" {
            url += "GetItems"
            method = .post
            parameters["query"] = [
                "ViewXml": "<View>\(camlQuery)</View>"
            ] as NSDictionary
        }else {
            if let query = withQuery {
                url += JunoHelper.shared.parseQuery(query: query)
            }
        }
        
        if nextPage != "" {
            url = ""
        }
        
        Connection.shared.request(method: method, resource: .SharePoint, controllerName: url, endPoint: nextPage, parameters: parameters) { (success, error) in
            
            let spList = SPList(listName: url)
            
            if let dict = success {
                if let nextPage = dict["odata.nextLink"] as? String {
                    spList.nextPage = nextPage
                }
                if let resultList = dict.value(forKeyPath: "value") as? NSArray {
                    for item in resultList {
                        if let result = item as? NSDictionary {
                            let spListItem = SPListItem(id: 0, listName: list.listName, dictionary: result)
                            spList.listItems.append(spListItem)
                        }
                    }
                }
            }
            completionHandler(spList, error)
        }
    }
    
    //get sharepoint list item
    //@params: listName: String
    //@params: itemId: Int
    //completionHandler: (SpListItem)
    //type: GET
    //method access: public
    public func getListItem(item: SPListItem, withQuery: [String: AnyObject]?, subSite: String = "", listPrefix: String = "/Lists", completionHandler: @escaping SPListItemHandler){
        
        item.updateSubSite(subSite: subSite, listPrefix: listPrefix)
        
        var url: String = "\(self.listPrefix)\(item.url)"
        
        if subSite != "" {
            if let _siteName = self.siteName {
                url = "\(_siteName)/\(subSite)/_api/web/\(item.url)"
            }
        }
        
        if let query = withQuery {
            url += JunoHelper.shared.parseQuery(query: query)
        }
        
        Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
            
            if let dict = success {
                let spListItem = SPListItem(id: item.id, listName: item.listName, dictionary: dict)
                completionHandler(spListItem, error)
            }
        }
    }
    
    //get sharepoint document items
    //@params: subSite: String
    //@params: serverRelativeUrl: String
    //completionHandler: (SpFile, SpFolder)
    //type: GET
    //method access: public
    public func getDocuments(serverRelativeUrl: String, withQuery: [String: AnyObject]?, type: String, completionHandler: @escaping SPDocumentHandler){
        
        var url: String = "\(serverRelativeUrl)\(type != "" ? "/\(type)" : "")"
        
        if let query = withQuery {
            url += JunoHelper.shared.parseQuery(query: query)
        }
        
        Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
            
            var folderList = [SPFolder]()
            var fileList = [SPFile]()
            if let dict = success {
                
                if type == "" {
                    //folder operations
                    if let list = dict["Folders"] as? NSArray {
                        folderList = self.folderOperation(list: list)
                    }
                    
                    // file operations
                    if let list = dict["Files"] as? NSArray {
                        fileList = self.fileOperation(list: list)
                    }
                }else {
                    if type == "Folders" {
                        if let list = dict["value"] as? NSArray {
                            folderList = self.folderOperation(list: list)
                        }
                    }else {
                        if let list = dict["value"] as? NSArray {
                            fileList = self.fileOperation(list: list)
                        }
                    }
                }
                
                completionHandler((folderList, fileList), error)
            }
        }
    }
    
    private func folderOperation(list: NSArray) -> [SPFolder] {
        var folderList = [SPFolder]()
        for item in list {
            if let result = item as? NSDictionary {
                let spFolder = SPFolder(dict: result)
                folderList.append(spFolder)
            }
        }
        return folderList
    }
    
    private func fileOperation(list: NSArray) -> [SPFile] {
        var fileList = [SPFile]()
        for item in list {
            if let result = item as? NSDictionary {
                let spFile = SPFile(dict: result)
                fileList.append(spFile)
            }
        }
        return fileList
    }
    
    //get sharepoint user information list
    //completionHandler: (NSDictionary)
    //type: GET
    //method access: public
    public func getUserInformationList(withQuery: [String: AnyObject]?, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            var url: String = "\(siteName)/_vti_bin/ListData.svc/UserInformationList"
            if let query = withQuery {
                url += JunoHelper.shared.parseQuery(query: query)
            }
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //get sharepoint user's followed people
    //completionHandler: (NSDictionary)
    //type: GET
    //method access: public
    public func getPeopleFollowedByMe(withQuery: [String: AnyObject]?, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            var url: String = "\(siteName)/_api/SP.UserProfiles.PeopleManager/getPeopleFollowedByMe"
            if let query = withQuery {
                url += JunoHelper.shared.parseQuery(query: query)
            }
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //get sharepoint current user properties
    //completionHandler: (NSDictionary)
    //type: GET
    //method access: public
    public func getMyProperties(withQuery: [String: AnyObject]?, completionHandler: @escaping(NSDictionary?, NSDictionary?)->()) {
        if let siteName = self.siteName {
            var url: String = "\(siteName)/_api/SP.UserProfiles.PeopleManager/getmyproperties"
            if let query = withQuery {
                url += JunoHelper.shared.parseQuery(query: query)
            }
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                completionHandler(success, error)
            }
        }
    }
    
    //set single property
    //completionHandler: (NSDictionary)
    //type: GET
    //method access: public
    public func setSingleProperty(query: [String: AnyObject], completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/SP.UserProfiles.PeopleManager/SetSingleValueProfileProperty"
            
            self.getFormDigestValue { (digest) in
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: query, headers: ["X-RequestDigest": digest] as [String: AnyObject]) { (success, error) in
                    if error == nil {
                        if let dict = success {
                            completionHandler(dict)
                        }
                    }
                }
            }
        }
    }
    
    //get sharepoint user's properties
    //completionHandler: (NSDictionary)
    //type: GET
    //method access: public
    public func getPropertiesFor(accountName: String, withQuery: [String: AnyObject]?, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let replacedStr: String = accountName.replacingOccurrences(of: "#", with: "%23").replacingOccurrences(of: "|", with: "%7C")
            var url: String = "\(siteName)/_api/SP.UserProfiles.PeopleManager/getpropertiesfor(accountName=@v)?@v='\(replacedStr)'"
            if let query = withQuery {
                url += JunoHelper.shared.parseQuery(query: query)
            }
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //followOperations people
    //type: String (follow | stopfollowing)
    //type: POST
    //method access: public
    public enum FollowType: String {
        case follow = "follow"
        case stopfollowing = "stopfollowing"
    }
    
    public func followOperations(followType: FollowType, accountName: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let replacedStr: String = accountName.replacingOccurrences(of: "#", with: "%23").replacingOccurrences(of: "|", with: "%7C")
            let url: String = "\(siteName)/_api/social.following/\(followType.rawValue)(accountName=@v)?@v='\(replacedStr)'"
            
            self.getFormDigestValue { (digest) in
                Connection.shared.request(method: .post,
                                          resource: .SharePoint,
                                          controllerName: url,
                                          headers: ["X-RequestDigest": digest] as [String: AnyObject]) { (success, error) in
                    if error == nil {
                        if let dict = success {
                            completionHandler(dict)
                        }
                    }
                }
            }
        }
    }
    
    //get sharepoint publishing image
    //completionHandler: (String)
    //type: GET
    //method access: public
    public func getPublisingImage(imageUrl: String, completionHandler: @escaping(String) ->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/\(imageUrl)?$select=Image"
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                if error == nil {
                    if let dict = success {
                        if let path = dict["Image"] as? String {
                            completionHandler(path)
                        }
                    }
                }
            }
        }
    }
    
    //save sharepoint list item
    //@params: item: SPListItem
    //completionHandler: (SPListItem)
    //type: POST
    //method access: only framework
    public func saveListItem(item: SPListItem, subSite: String = "", listPrefix: String = "/Lists", completionHandler: @escaping SPListItemHandler){
        
        if !item.withId {
            item.updateSubSite(subSite: subSite, listPrefix: listPrefix)
        }
        
        var url: String = "\(self.listPrefix)\(item.url)"
        
        if subSite != "" {
            if let _siteName = self.siteName {
                url = "\(_siteName)/\(subSite)/_api/web/\(item.url)"
            }
        }
        
        var headers = [String: AnyObject]()
        
        self.getFormDigestValue { (formDigestValue) in
            headers["X-RequestDigest"] = formDigestValue as AnyObject
            
            // If the item has 'Id', means that is not a new item,
            //so set the call headers for make an update.
            if !item.isNew() {
                headers["X-HTTP-Method"] = "MERGE" as AnyObject
                headers["IF-MATCH"] = "*" as AnyObject
            }
            
            let metadata = [String: AnyObject]()
            
            if let dict = item.dictionary {
                let requestDictionary = metadata.merging(dict as! [String : AnyObject], uniquingKeysWith: { (_, last) in last })
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary, headers: headers, completionHandler: { (success, error) in
                    let spListItem = SPListItem(id: item.id, listName: item.listName, dictionary: success)
                    completionHandler(spListItem, error)
                })
            }
            
            //            //get list properties for CRUD operations
            //            self.getListProperties(listName: item.listName, completionHandler: { (listItemEntityTypeFullName) in
            //
            //                let metadata = [
            //                    "__metadata": [
            //                        "type": listItemEntityTypeFullName
            //                    ]
            //                ] as [String: AnyObject]
            //
            //
            //            })
        }
    }
    
    //change item relative path
    //@params: item: SPListItem
    //completionHandler: (Bool)
    //type: POST
    //method access: public
    public func moveTo(fileUrl: String, newUrl: String, completionHandler: @escaping(Bool)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/web/getfilebyserverrelativeurl('\(fileUrl)')/moveto(newurl='\(newUrl)',flags=1)"
            
            var headers = [String: AnyObject]()
            self.getFormDigestValue { (formDigestValue) in
                headers["X-RequestDigest"] = formDigestValue as AnyObject
                var status: Bool = false
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, headers: headers, completionHandler: { (success, error) in
                    if error == nil {
                        status = true
                    }
                    completionHandler(status)
                })
            }
            
        }
    }
    
    //delete sharepoint list item
    //@params: item: SPListItem
    //completionHandler: (Bool)
    //type: POST
    //method access: only framework
    public func deleteListItem(item: SPListItem, permanent: Bool, completionHandler: @escaping(Bool)->()){
        
        var url: String = "\(self.listPrefix)\(item.url)"
        
        var headers = [String: AnyObject]()
        
        self.getFormDigestValue { (formDigestValue) in
            headers = [
                "X-RequestDigest": formDigestValue,
            ] as [String: AnyObject]
            
            if permanent {
                headers["X-HTTP-Method"] = "DELETE" as AnyObject
                headers["IF-MATCH"] = "*" as AnyObject
            }else {
                url += "/recycle"
            }
            
            var status: Bool = false
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, headers: headers, completionHandler: { (success, error) in
                if error == nil {
                    status = true
                }
                completionHandler(status)
            })
            
        }
    }
    
    //upload attachment to SPListItem
    //method access: only framework
    public func uploadAttachment(itemUrl: String, file: Data, fileName: String = "\(String(Date().timeIntervalSince1970)).png", completionHandler: @escaping(SPAttachment)->()){
        
        let url: String = "\(self.listPrefix)\(itemUrl)/AttachmentFiles/add(FileName='\(fileName)')"
        
        var headers = [String: AnyObject]()
        
        self.getFormDigestValue { (formDigestValue) in
            headers["X-RequestDigest"] = formDigestValue as AnyObject
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, headers: headers, isBinary: file, completionHandler: { (success, error) in
                if error == nil {
                    let attachment = SPAttachment()
                    if let fileName = success?.value(forKeyPath: "FileName") as? String {
                        attachment.fileName = fileName
                    }
                    if let filePath = success?.value(forKeyPath: "ServerRelativeUrl") as? String {
                        attachment.filePath = filePath
                    }
                    completionHandler(attachment)
                }
            })
            
        }
    }
    
    //upload file to document library
    public func uploadFileToDocumentLibrary(folderName: String, file: Data, completionHandler: @escaping(NSDictionary)->()){
        
        let fileName: String = "\(String(Date().timeIntervalSince1970)).jpg"
        
        self.getFormDigestValue { (formDigestValue) in
            let headers = [
                "X-RequestDigest": formDigestValue
            ] as [String: AnyObject]
            
            if let siteName = self.siteName {
                let url: String = "\(siteName)/_api/Web/getfolderbyserverrelativeurl('\(siteName)/\(folderName)')/Files/Add(url='\(fileName)',overwrite=true)"
                if let link = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    if let replacedPath = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        Connection.shared.request(method: .post, resource: .SharePoint, controllerName: replacedPath, headers: headers, isBinary: file, completionHandler: { (success, error) in
                            if error == nil {
                                if let dict = success {
                                    completionHandler(dict)
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    //delete attachment file from SPListItem
    //method access: only framework
    public func deleteAttachment(itemUrl: String, fileName: String, completionHandler: @escaping(Bool)->()){
        var headers = [String: AnyObject]()
        
        let url: String = "\(self.listPrefix)\(itemUrl)/AttachmentFiles('\(fileName)')"
        
        self.getFormDigestValue { (formDigestValue) in
            headers = [
                "X-RequestDigest": formDigestValue,
                "X-HTTP-Method": "DELETE"
            ] as [String: AnyObject]
            
            var status: Bool = false
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, headers: headers, completionHandler: { (success, error) in
                if error == nil {
                    status = true
                }
                completionHandler(status)
            })
        }
    }
    
    //people search
    public func search(query: [String: AnyObject], completionHandler: @escaping(NSArray, Int)->()) {
        if let siteName = self.siteName {
            var url: String = "\(siteName)/_api/search/query"
            url += JunoHelper.shared.parseQuery(query: query, avoidPrefix: true)
            if let replaceStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                Connection.shared.request(method: .get, resource: .SharePoint, controllerName: replaceStr) { (success, error) in
                    var result: NSArray = []
                    var totalRow: Int = 0
                    if error == nil {
                        if let dict = success {
                            if let _result = dict.value(forKeyPath: "PrimaryQueryResult.RelevantResults.Table.Rows") as? NSArray {
                                result = _result
                            }
                            
                            if let _totalRow = dict.value(forKeyPath: "PrimaryQueryResult.RelevantResults.TotalRows") as? Int {
                                totalRow = _totalRow
                            }
                        }
                    }
                    completionHandler(result, totalRow)
                }
            }
        }
    }
    
    //get feed list
    public func getFeedList(dateTime: String = "", completionHandler: @escaping(NSDictionary)->()) {
        var olderTag: String = "(SortOrder=1)"
        
        if dateTime != "" {
            olderTag = "(SortOrder=1,OlderThan=@d)"
        }
        
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/social.feed/actor(item=@v)/feed\(olderTag)?@v='\(self.siteUrl)\(siteName)/newsfeed.aspx'&@d=datetime'\(dateTime)'"
            
            Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //get full thread contains all replies
    public func getFeedById(id: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/social.feed/post"
            
            let requestDictionary = [
                "ID": id
            ] as [String: AnyObject]
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                } else {
                    completionHandler(error!)
                }
            }
        }
    }
    
    //create feed post
    public func createFeedPost(threadId: String = "", text: String, contentItems: [[String: AnyObject]] = [], completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            var url: String = "\(siteName)/_api/social.feed/actor(item=@v)/feed/post?@v='\(self.siteUrl)\(siteName)/newsfeed.aspx'"
            
            if threadId != "" {
                url = "\(siteName)/_api/social.feed/post/reply"
            }
            
            var requestDictionary = [String: AnyObject]()
            var restCreationData = [String: AnyObject]()
            let creationData = [
                "ContentText": text,
                "UpdateStatusText": false,
                "ContentItems": contentItems
            ] as [String: AnyObject]
            
            if threadId != "" {
                restCreationData["ID"] = threadId as AnyObject
            }
            
            restCreationData["creationData"] = creationData as AnyObject
            
            requestDictionary = [
                "restCreationData": restCreationData as AnyObject
            ]
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //delete feed post
    public func deleteFeedPost(threadId: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/social.feed/post/delete"
            
            let requestDictionary = [
                "ID": threadId
            ] as [String: AnyObject]
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //like/unlike feed
    public func likeUnlikeFeed(action: String, threadId: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/social.feed/post/\(action)"
            
            let requestDictionary = [
                "ID": threadId
            ] as [String: AnyObject]
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    // get feed likers
    public func getFeedLikers(threadId: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_api/social.feed/post/likers"
            
            let requestDictionary = [
                "ID": threadId
            ] as [String: AnyObject]
            
            Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: requestDictionary) { (success, error) in
                if error == nil {
                    if let dict = success {
                        completionHandler(dict)
                    }
                }
            }
        }
    }
    
    //like/unlike list item
    public func likeUnlikeListItem(action: Bool, itemId: Int, listId: String, completionHandler: @escaping(NSDictionary)->()) {
        if let siteName = self.siteName {
            let url: String = "\(siteName)/_vti_bin/client.svc/ProcessQuery"
            
            let xml = """
            <Request xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Javascript Library">
            <Actions>
            <StaticMethod TypeId="{d9c758a9-d32d-4c9c-ab60-46fd8b3c79b7}" Name="SetLike" Id="0">
            <Parameters>
            <Parameter Type="String">{\(listId)}</Parameter>
            <Parameter Type="String">\(itemId)</Parameter>
            <Parameter Type="Boolean">\(action)</Parameter>
            </Parameters>
            </StaticMethod>
            </Actions>
            <ObjectPaths/>
            </Request>
            """
            
            var headers = [String: AnyObject]()
            self.getFormDigestValue { (formDigestValue) in
                headers["X-RequestDigest"] = formDigestValue as AnyObject
                headers["X-HTTP-Method"] = "MERGE" as AnyObject
                headers["IF-MATCH"] = "*" as AnyObject
                
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: ["xml": xml] as [String: AnyObject], headers: headers) { (success, error) in
                    if error == nil {
                        if let dict = success {
                            completionHandler(dict)
                        }
                    }
                }
                
            }
        }
    }
    
    // get current web information
    // query: [String: AnyObject]
    // type: POST
    // method access: public
    public func getCurrentWebInformation(withQuery: [String: AnyObject]?, subSite: String = "", completionHandler: @escaping(NSDictionary?)->()) {
        var url: String = ""
        
        if let _siteName = self.siteName {
            url = "\(_siteName)/\(subSite)/_api/web"
        }
        
        if let query = withQuery {
            url += JunoHelper.shared.parseQuery(query: query)
        }
        
        Connection.shared.request(method: .get, resource: .SharePoint, controllerName: url) { (success, error) in
            if error == nil {
                completionHandler(success)
            }else {
                completionHandler(error)
            }
        }
    }
    
    // batch request
    // query: [String: AnyObject]
    // type: POST
    // method access: public
    public func batchRequest(batchQuery: [AnyObject], completionHandler: @escaping SPListArrayHandler) {
        
        var batchContents = [String]()
        let resourceUrl = JunoConfig.tokenManager[.SharePoint]!.getUrl()
        let uuid = UUID().uuidString.lowercased()
        
        var siteName = ""
        var controllerName: String = ""
        if let _siteName = self.siteName {
            siteName = _siteName
            controllerName = "\(siteName)"
        }
        
        for query in batchQuery {
            if  let spList = query["spList"] as? SPList,
                let spQuery = query["spQuery"] as? [String: AnyObject] {
                if !spList.withId {
                    spList.updateSubSite(subSite: spList.subSite, listPrefix: "/Lists")
                }
                
                var url: String = "\(resourceUrl)\(self.listPrefix)\(spList.listUrl)"
                
                if spList.subSite != "" {
                    if siteName != "" {
                        url = "\(resourceUrl)\(siteName)/\(spList.subSite)/_api/web/\(spList.listUrl)"
                        controllerName = "\(siteName)/\(spList.subSite)"
                    }
                }
                
                url += JunoHelper.shared.parseQuery(query: spQuery)
                
                let batchBody = """
                --batch_\(uuid)
                Content-Type: application/http
                Content-Transfer-Encoding: binary
                
                GET \(url) HTTP/1.1
                Accept: application/json
                
                """
                
                batchContents.append(batchBody)
            }
        }
        
        batchContents.append("--batch_\(uuid)--")
        
        let batchBody = batchContents.joined(separator: "\r\n")
        
        let parameters = [
            "xml": batchBody
        ] as [String: AnyObject]
        
        let headers = ["Content-Type": "multipart/mixed;boundary=batch_\(uuid)"] as [String: AnyObject]
        
        Connection.shared.request(method: .post, resource: .SharePoint, controllerName: "\(controllerName)/_api/$batch", parameters: parameters, headers: headers) { (success, error) in
            
            var spListArray = [SPList]()
            
            if let dict = success {
                
                if let batch = dict["batch"] as? String {
                    let responseLines = batch.components(separatedBy: "\n")
                    
                    for currentLine in responseLines {
                        if let dict = JunoHelper.shared.parseJSONString(str: currentLine) as? NSDictionary{
                            let spList = SPList(listName: "")
                            if let nextPage = dict["odata.nextLink"] as? String {
                                spList.nextPage = nextPage
                            }
                            if let resultList = dict.value(forKeyPath: "value") as? NSArray {
                                for item in resultList {
                                    if let result = item as? NSDictionary {
                                        let spListItem = SPListItem(id: 0, listName: spList.listName, dictionary: result)
                                        spList.listItems.append(spListItem)
                                    }
                                }
                            }
                            spListArray.append(spList)
                        }
                    }
                }
            }
            completionHandler(spListArray, error)
        }
    }
    
    // create new folder
    // type: POST
    // params: listName: String
    // params: folderPath: String
    // method access: public
    public func createFolder(listName: String, folderName: String, subSite: String = "", completionHandler: @escaping(_ success: NSDictionary?, _ error: NSDictionary?) ->()) {
        if let siteName = self.siteName {
            let url = "\(siteName)\(subSite != "" ? "/\(subSite)" : "")/_api/web/GetFolderByServerRelativePath(DecodedUrl=@a1)/AddSubFolderUsingPath(DecodedUrl=@a2)?@a1='\(siteName)\(subSite != "" ? "/\(subSite)" : "")/Lists/\(listName)'&@a2='\(folderName)'"
            
            var headers = [String: AnyObject]()
            
            self.getFormDigestValue { (formDigestValue) in
                headers["X-RequestDigest"] = formDigestValue as AnyObject
                                
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: [:], headers: headers, completionHandler: completionHandler)
            }
        }
    }
    
    // create list item into folder
    // type: POST
    // payload: NSDictionary
    // method access: public
    public func saveListItemIntoFolder(payload: [String: AnyObject], listName: String, subSite: String = "", completionHandler: @escaping(_ success: NSDictionary?, _ error: NSDictionary?) ->()) {
        if let siteName = self.siteName {
            let url = "\(siteName)\(subSite != "" ? "/\(subSite)" : "")/_api/web/getList('\(siteName)\(subSite != "" ? "/\(subSite)" : "")/Lists/\(listName)')/AddValidateUpdateItemUsingPath"
            var headers = [String: AnyObject]()
            
            self.getFormDigestValue { (formDigestValue) in
                headers["X-RequestDigest"] = formDigestValue as AnyObject
                                
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: payload, headers: headers, completionHandler: completionHandler)
            }
        }
    }
    
    // render data as stream
    // type: POST
    // payload: NSDictionary
    // method access: public
    public func renderListDataAsStream(payload: [String: AnyObject], listName: String, subSite: String = "", type: String = "/Lists", nextPage: String = "", completionHandler: @escaping(_ success: NSDictionary?, _ error: NSDictionary?) ->()) {
        if let siteName = self.siteName {
            let url = "\(siteName)\(subSite != "" ? "/\(subSite)" : "")/_api/web/getList('\(siteName)\(subSite != "" ? "/\(subSite)" : "")\(type)/\(listName)')/RenderListDataAsStream\(nextPage != "" ? nextPage : "")"
            
            var headers = [String: AnyObject]()
            
            self.getFormDigestValue { (formDigestValue) in
                headers["X-RequestDigest"] = formDigestValue as AnyObject
                
                Connection.shared.request(method: .post, resource: .SharePoint, controllerName: url, parameters: payload, headers: headers, completionHandler: completionHandler)
            }
        }
    }
}


