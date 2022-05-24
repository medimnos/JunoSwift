//
//  Authentication.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import MSAL

public class Authentication {
    
    public static var shared = Authentication()
    
    private init(){
        self.scopes = self.defaultScopes
    }
    
    public var userClaims: NSString?
    private var upn = ""
    private var idToken = ""
    private var expireDate: Date!
    public var viewController: UIViewController!
    private var accountIdentifier: String!
    
    var defaultScopes: [Resource: [String]] = [
        .Graph: [
            "User.ReadWrite",
            "User.ReadBasic.All",
            "MailboxSettings.ReadWrite",
            "Calendars.ReadWrite"
        ],
        .SharePoint: [
            "User.Read.All",
            "Sites.Search.All",
            "MyFiles.Read",
            "MyFiles.Write",
            "AllSites.Read",
            "AllSites.Write"
        ]
    ]
    
    var scopes: [Resource: [String]] = [:]
    
    var applicationContext: MSALPublicClientApplication?
    
    //MSAL authentication context object
    private func getAuthContext() -> String {
        return "https://login.microsoftonline.com/\(OGOOConfig.tenant)"
    }
    
    // get scope for resource name
    public func getScopeList(resource: Resource) -> [String] {
        var scopeList = [String]()
        
        if let list = self.scopes[resource] {
            for item in list {
                let result = "\(resource == .SharePoint ? "https://\(OGOOConfig.siteUrl)/" : "")\(item)"
                scopeList.append(result)
            }
        }
        
        return scopeList
    }
    
    // extend default scope list
    public func extendScopeList(resource: Resource, scopes: [String]) {
        self.scopes[resource] = scopes
    }
    
    //first time login
    //when users login for the first time
    //app use only graph resouce
    //@completionHandler: Bool
    //method access: public
    public func acquireToken(promptBehavior: MSALPromptType = .default, viewController: UIViewController?, completionHandler: @escaping(Bool)->()){
        self.getToken(resource: .Graph, promptBehavior: promptBehavior, viewController: viewController, completionHandler: completionHandler)
    }
    
    //only authenticated users call this method
    //with different resource name
    //example: https://ogoodigital.sharepoint.com etc.
    //@params: resource: Resource (example=https://graph.microsoft.com)
    //@completionHandler: Bool
    //method access: public
    public func acquireTokenWithResource(resource: Resource, viewController: UIViewController?, completionHandler: @escaping(Bool)->()){
        self.getToken(resource: resource, viewController: viewController, completionHandler: completionHandler)
    }
    
    //ADAL token generator
    //this method generate Bearer token with ADAL SDK
    //@params: resource: Resource (example=https://graph.microsoft.com)
    //@completionHandler: Bool
    //method access: private
    private func getToken(resource: Resource, promptBehavior: MSALPromptType = .default, viewController: UIViewController?, completionHandler: @escaping(Bool)->()){
        
        self.viewController = viewController
        
        let authority = self.getAuthContext()
        
        if let application = self.createApplication() {
            if let parentViewController = self.viewController {
                let webviewParameters = MSALWebviewParameters.init(authPresentationViewController: parentViewController)
                let interactiveParameters = MSALInteractiveTokenParameters(scopes: self.getScopeList(resource: resource), webviewParameters: webviewParameters)
                interactiveParameters.promptType = promptBehavior
                
                do {
                    interactiveParameters.authority = try MSALAuthority(url: URL(string: authority)!)
                    if try application.allAccounts().isEmpty {
                        throw NSError.init(domain: "MSALErrorDomain", code: MSALError.interactionRequired.rawValue, userInfo: nil)
                    } else {
                        if self.accountIdentifier == nil {
                            throw NSError.init(domain: "MSALErrorDomain", code: MSALError.interactionRequired.rawValue, userInfo: nil)
                        }else {
                            if let identifier = self.accountIdentifier {
                                guard let account = try? application.account(forIdentifier: identifier) else {return}
                                
                                let silentTokenParameters = MSALSilentTokenParameters(scopes: self.getScopeList(resource: resource), account: account)
                                silentTokenParameters.authority = try MSALAuthority(url: URL(string: authority)!)
                                application.acquireTokenSilent(with: silentTokenParameters) { (result, error) in
                                    if error == nil {
                                        self.processMSALResult(result: result, error: error, resource: resource, completionHandler: completionHandler)
                                    } else {
                                        self.removedCachedUser {
                                            interactiveParameters.promptType = .login
                                            self.login(application: application, interactiveParameters: interactiveParameters, resource: resource, completionHandler: completionHandler)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }  catch let error as NSError {
                    if error.code == MSALError.interactionRequired.rawValue {
                        self.login(application: application, interactiveParameters: interactiveParameters, resource: resource, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                } catch {
                    print("error")
                }
            }
        }
    }
    
    func login(application: MSALPublicClientApplication, interactiveParameters: MSALInteractiveTokenParameters, resource: Resource, completionHandler: @escaping(_ isAuth: Bool)->()) {
        application.acquireToken(with: interactiveParameters) { (result, error) in
            if error == nil {
                self.processMSALResult(result: result, error: error, resource: resource, completionHandler: completionHandler)
            }
        }
    }
    
    func processMSALResult(result: MSALResult?, error: Error?, resource: Resource, completionHandler: @escaping(Bool)->()) {
        
        guard let _ = result, error == nil else {
            print(error!.localizedDescription)
            completionHandler(false)
            return
        }
        
        if let token = result?.accessToken {
            OGOOConfig.tokenManager[resource] = TokenStorage(resourceName: resource, token: token, resourceUrl: OGOOConfig.resources[resource] as! String)
        }
        
        let info = result?.account.accountClaims
        
        if let _idToken = result?.idToken {
            self.idToken = _idToken
        }
        
        if let upnName = result?.account.username {
            self.upn = upnName
        }
        
        if let tokenExpireDate = result?.expiresOn {
            self.expireDate = tokenExpireDate
        }
        
        self.accountIdentifier = result?.account.identifier
        UserDefaults.standard.setValue(result?.account.identifier, forKey: "JUNO_IDENTIFIER")
        
        do {
            let dict = try JSONSerialization.data(withJSONObject: info ?? [:], options: .prettyPrinted)
            let json = NSString(data: dict, encoding: String.Encoding.utf8.rawValue)
            self.userClaims = json
            if OGOOConfig.debugMode {
                print(resource, result?.accessToken)
                print(json)
            }
            completionHandler(true)
        }catch _ as NSError {
            completionHandler(false)
        }
    }
    
    public func getTokenForResource(resource: Resource) -> String {
        var token: String = ""
        
        if let resourceToken = OGOOConfig.tokenManager[resource] {
            token = resourceToken.getToken()
        }
        
        return token
    }
    
    public func getIdToken() -> String {
        return self.idToken
    }
    
    public func getUpnName() -> String {
        return self.upn
    }
    
    public func getExpireDate() -> Date {
        return self.expireDate
    }
    
    // Clear the ADAL token cache and remove this application's cookies.
    //method access: public
    public func clearCredentials(completionHandler: @escaping()->()){
        self.removedCachedUser {
            OGOOConfig.tokenManager = [:]
            
            // Remove all the cookies from this application's sandbox. The authorization code is stored in the cookies and ADAL will try to get to access tokens based on auth code in the cookie.
            let cookieStore = HTTPCookieStorage.shared
            if let cookies = cookieStore.cookies {
                for cookie in cookies {
                    cookieStore.deleteCookie(cookie)
                }
            }
            
            self.scopes = self.defaultScopes
            
            self.applicationContext = nil
            UserDefaults.standard.removeObject(forKey: "JUNO_IDENTIFIER")
            UserDefaults.standard.synchronize()
            completionHandler()
        }
    }
    
    private func removedCachedUser(completionHandler: ()->()) {
        if let application = self.createApplication() {
            do {
                let accounts = try application.allAccounts()
                for account in accounts {
                    try application.remove(account)
                }
            }catch let err as NSError {
                print(err.debugDescription)
            }
        }
        completionHandler()
    }
    
    private func createApplication() -> MSALPublicClientApplication? {
        if self.applicationContext == nil {
            let config = MSALPublicClientApplicationConfig(clientId: OGOOConfig.clientId)
            if let application = try? MSALPublicClientApplication(configuration: config) {
                self.applicationContext = application
            }
            
            if let identifier = UserDefaults.standard.object(forKey: "JUNO_IDENTIFIER") as? String {
                self.accountIdentifier = identifier
            }
            
        }
        
        return self.applicationContext
    }
}
