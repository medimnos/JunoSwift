//
//  OGOO.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

public class OGOO {
    
    //create singleton instance
    public static var shared = OGOO()
    
    private init(){}
    
    //initialize OGOO framework
    //@params: clientId: String - application id from Azure AD
    //@params redirectUri: String - when application authentication is finished
    public func initialize(clientId: String, redirectUri: String, tenant: String, debugMode: Bool = false){
        OGOOConfig.clientId = clientId
        OGOOConfig.redirectUri = redirectUri
        OGOOConfig.debugMode = debugMode
        OGOOConfig.siteUrl = tenant
        
        let tenantName = tenant.replacingOccurrences(of: "sharepoint", with: "onmicrosoft")
        OGOOConfig.tenant = tenantName
    }
}
