//
//  Juno.swift
//  Juno
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class Juno {
    
    //create singleton instance
    public static var shared = Juno()
    
    private init(){}
    
    //initialize Juno framework
    //@params: clientId: String - application id from Azure AD
    //@params redirectUri: String - when application authentication is finished
    public func initialize(clientId: String, redirectUri: String, tenant: String, debugMode: Bool = false){
        JunoConfig.clientId = clientId
        JunoConfig.redirectUri = redirectUri
        JunoConfig.debugMode = debugMode
        JunoConfig.siteUrl = tenant
        
        let tenantName = tenant.replacingOccurrences(of: "sharepoint", with: "onmicrosoft")
        JunoConfig.tenant = tenantName
    }
}
