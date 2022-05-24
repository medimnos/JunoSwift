//
//  JunoHelper.swift
//  Juno
//
//  Created by Uğur Uğurlu on 14.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation

public class JunoHelper {
    
    //create singleton instance
    public static var shared = JunoHelper()
    
    private init(){}
    
    //parse query
    //params: restQuery: [String: AnyObject]
    //return value: String
    //method access: only framework
    public func parseQuery(query: [String: AnyObject], avoidPrefix: Bool = false) -> String{
        var strQuery: String = ""
        let reservedKeys = ["select", "top", "filter", "orderby", "expand"]
        
        for (key, value) in query {
            let param = "\(reservedKeys.contains(key) ? "$" : "")\(key)=\(value)"
            strQuery += (strQuery == "" ? "?" : "&") + param
        }
        
        return strQuery
    }
    
    public func parseJSONString(str: String) -> Any? {
        let data = str.data(using: String.Encoding.utf8, allowLossyConversion: false)
        guard let jsonData = data else { return nil }
        do { return try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) }
        catch { return nil }
    }
}
