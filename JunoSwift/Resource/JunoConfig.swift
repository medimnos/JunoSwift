//
//  JunoConfig.swift
//  Juno
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation

class JunoConfig {
    
    static var clientId: String = ""
    static var redirectUri: String = ""
    static var tokenManager = [Resource: TokenStorage]()
    static var debugMode: Bool = false
    static var tenant: String = ""
    static var siteUrl: String = ""
    static var resources = [
        .Graph : "https://graph.microsoft.com",
        .Outlook : "https://outlook.office.com",
        .SharePoint : ""
        ] as [Resource: AnyObject]
    
//    static var SHAREPOINT_HOSTNAME = "*.sharepoint.com";
//    static var GRAPH_HOSTNAME = "graph.microsoft.com";
//    static var AZURE_HOSTNAME = "*.azurewebsites.net";
//    static var SP_SHA256_1 = "bVzBrlJfqLYNfnHX7VJVV7jfctE59PvFZrwjalzFmso="
//    static var SP_SHA256_2 = "UgpUVparimk8QCjtWQaUQ7EGrtrykc/L8N66EhFY3VE="
//    static var SP_SHA256_3 = "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E="
//    static var GRAPH_SHA256_1 = "RkkMSg01KoOQE6eWBay0C9WmXAzDvvarCaHPHF7F4Gg="
//    static var GRAPH_SHA256_2 = "Wl8MFY+9zijGG8QgEHCAK5fhA+ydPZxaLQOFdiEPz3U="
//    static var GRAPH_SHA256_3 = "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY="
//    static var AZURE_SHA256_1 = "aKYnL1z7pefIRzAjU4c6uPz+ZwKM5lgH4jvYYDEoWTo="
//    static var AZURE_SHA256_2 = "1wMGTin0PoCN5O41h0+XIHXuzGRwDEa8ehHf7wSdSQE="
//    static var AZURE_SHA256_3 = "Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o="
}
