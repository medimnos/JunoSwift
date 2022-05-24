//
//  Graph.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 10.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import Alamofire

public class Graph {
    //create singleton instance
    public static var shared = Graph()
    
    private init(){}
    
    private var apiVersion = "/v1.0"
    
    //get user site information
    //completionHandler: (String)
    public func getSiteInformation(completionHandler: @escaping(String)->()){
        
        var webUrl: String = ""
        
        Connection.shared.request(method: .get, resource: .Graph, controllerName: "\(self.apiVersion)/sites/root") { (success, error) in
            
            if let dict = success {
                if let _webUrl = dict.value(forKeyPath: "siteCollection.hostname") as? String {
                    webUrl = _webUrl
                }
                
                if let spResourceName = dict["webUrl"] as? String {
                    OGOOConfig.tokenManager[.Outlook] = TokenStorage(resourceName: .Outlook, token: "", resourceUrl: OGOOConfig.resources[.Outlook] as! String)
                    OGOOConfig.tokenManager[.SharePoint] = TokenStorage(resourceName: .SharePoint, token: "", resourceUrl: spResourceName)
                }
            }
            completionHandler(webUrl)
        }
    }
    
    //get or update current user's mailbox auto reply settings
    public func  updateMailBoxSettings(method: HTTPMethod, upn: String = "me", requestDictionary: [String: AnyObject] = [:], completionHandler: @escaping(NSDictionary?, NSDictionary?)->()) {
        let url: String = "\(self.apiVersion)/\(upn)/MailboxSettings"
        
        Connection.shared.request(method: method, resource: .Graph, controllerName: url, parameters: requestDictionary) { (success, error) in
            completionHandler(success, error)
        }
    }
    
    //get user information
    //@params: user principal name: String (default: me)
    //completionHandler: (User)
    public func getUserInformation(upn: String = "me"){
        
    }
    
    //get user photo
    //@params: user principal name: String (default: me)
    //completionHandler: (Data)
    func getUserPhoto(upn: String = "me"){
        let _: String = "\(upn)/photo/$value"
    }
    
    /**
     update profile picture
     */
    public func updateProfilePicture(imageData: Data, completionHandler: @escaping()->()) {
        let headers = [
            "Content-Type": "image/jpeg"
            ] as [String: AnyObject]
        let url: String = "\(self.apiVersion)/me/photo/$value"
        Connection.shared.request(method: .put, resource: .Graph, controllerName: url, headers: headers, isBinary: imageData, completionHandler: { (success, error) in
            completionHandler()
        })
    }
    
    /**
     create event
     */
    public func createEvent(requestDictionary: [String: AnyObject], completionHandler: @escaping(NSDictionary?, NSDictionary?) ->()) {
        let url: String = "\(self.apiVersion)/me/calendar/events"
        Connection.shared.request(method: .post, resource: .Graph, controllerName: url, parameters: requestDictionary) { (success, error) in
            completionHandler(success, error)
        }
    }
    
    // get event
    public func getEvents(singleValueExtendedProperties: String, value: String, completionHandler: @escaping(NSDictionary?, NSDictionary?) ->()) {
        let url: String = "\(self.apiVersion)/me/calendar/events?$filter=singleValueExtendedProperties/Any(ep:%20ep/id%20eq%20'\(singleValueExtendedProperties)'%20and%20ep/value%20eq%20'\(value)')"
        Connection.shared.request(method: .get, resource: .Graph, controllerName: url, parameters: [:]) { (success, error) in
            completionHandler(success, error)
        }
    }
    
    // delete event
    public func deleteEvent(eventId: String, completionHandler: @escaping(NSDictionary?, NSDictionary?) ->()) {
        let url: String = "\(self.apiVersion)/me/calendar/events/\(eventId)"
        Connection.shared.request(method: .delete, resource: .Graph, controllerName: url, parameters: [:]) { (success, error) in
            completionHandler(success, error)
        }
    }
}
