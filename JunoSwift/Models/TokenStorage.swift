//
//  TokenStorage.swift
//  Juno
//
//  Created by Uğur Uğurlu on 11.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import UIKit

class TokenStorage: NSObject {
    private(set) var resourceName: Resource?
    private(set) var token: String?
    private(set) var resourceUrl: String?
    
    init(resourceName: Resource, token: String, resourceUrl: String) {
        self.resourceName = resourceName
        self.token = token
        self.resourceUrl = resourceUrl
    }
}

extension TokenStorage {
    
    func getToken() -> String{
        var accessToken: String = ""
        
        if let _token = self.token {
            accessToken = _token
        }
        return accessToken
    }
    
    func getUrl() -> String{
        var url: String = ""
        
        if let _url = self.resourceUrl {
            url = _url
        }
        return url
    }
}
