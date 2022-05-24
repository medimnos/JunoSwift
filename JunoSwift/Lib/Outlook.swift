//
//  Outlook.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 10.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import Alamofire

public class Outlook {
    //create singleton instance
    public static var shared = Outlook()
    
    private let apiVersion: String = "/api/v2.0/me/"
    
    private init(){}
    
}
