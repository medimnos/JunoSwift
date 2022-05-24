//
//  Log.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 15.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
public class Log {
    
    //create singleton instance
    public static var shared = Log()
    
    private init(){}

    public func addLog(err: NSError){
        print(err.userInfo)
    }
}
