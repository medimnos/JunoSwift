//
//  NetworkClient.swift
//  JunoSwift
//
//  Created by Uğur Uğurlu on 14.10.2021.
//

import Foundation
import Alamofire

public class NetworkClient: SessionDelegate {
    
    public static let shared = NetworkClient()
    
    public var session: Session!
    
    private init() {
        super.init()
        session = Session(configuration: .ephemeral, delegate: self)
    }
}
