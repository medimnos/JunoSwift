//
//  Connection.swift
//  OGOO
//
//  Created by Uğur Uğurlu on 10.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import Alamofire

class Connection {
    
    //create singleton instance
    static let shared = Connection()
    
    private init(){}
    
    typealias CompletionHandler = (_ success: NSDictionary?, _ error: NSDictionary?) -> ()
    
    //global connection manager
    //this method access private method and serializing raw data.
    //method: HTTPMethod (mandatory)
    //resource: Resource (mandatory)
    //controllerName: String (optional)
    //endPoint: String (optional)
    //parameters: (optional=default empty value)
    //headers: [String: AnyObject] (optional)
    //@ocompletionHandler: (CompletionHandler)
    //method access: framework only
    func request(method: HTTPMethod, resource: Resource, controllerName: String = "", endPoint: String = "", parameters: [String: AnyObject] = [:], headers: [String: AnyObject] = [:], isBinary: Data? = nil, completionHandler: @escaping CompletionHandler){
        
        self.beginRequest(method: method, resource: resource, controllerName: controllerName, endPoint: endPoint, parameters: parameters, headers: headers, isBinary: isBinary) { (response) in
            
            if let statusCode: Int = response.response?.statusCode {
                
                switch statusCode {
                //unauthorized
                case 401:
                    //re-connect ADAL SDK
                    Authentication.shared.acquireTokenWithResource(resource: resource, viewController: Authentication.shared.viewController, completionHandler: { (isAuth) in
                        if isAuth {
                            NotificationCenter.default.post(name: NSNotification.Name("TokenRefresh"), object: nil)
                        }else {
                            Authentication.shared.clearCredentials(completionHandler: {
                                completionHandler(nil, ["error": "Unauthorized user!"])
                            })
                        }
                    })
                    break
                //no content
                case 204:
                    completionHandler(["update": true], nil)
                    break
                case 503:
                    if OGOOConfig.debugMode {
                        print("------------------------RESPONSE------------------------------")
                        print("Resource: \(resource)")
                        print("Controller name: \(controllerName)")
                        print("Endpoint: \(endPoint)")
                        print("Request parameters: \(parameters)")
                        print("Status code: \(statusCode)")
                        print("------------------------RESPONSE------------------------------")
                    }
                    completionHandler(nil, ["error": true])
                    break
                default:
                    //process JSON string
                    if let rawData = response.data {
                        var success: NSDictionary?
                        var error: NSDictionary?
                        
                        if parameters["xml"] != nil {
                            let str = String(decoding: rawData, as: UTF8.self)
                            let dictionary = [
                                "batch": str
                            ] as NSDictionary
                            completionHandler(dictionary, nil)
                        }else {
                            do {
                                //serialize raw data
                                let data = try JSONSerialization.jsonObject(with: rawData, options: .allowFragments)
                                var dictionary: NSDictionary!
                                
                                if let dict = data as? NSDictionary {
                                    dictionary = dict
                                }
                                
                                if let dict = data as? NSArray {
                                    dictionary = [
                                        "data": dict
                                    ]
                                }
                                
                                if OGOOConfig.debugMode {
                                    print("------------------------RESPONSE------------------------------")
                                    print("Resource: \(resource)")
                                    print("Controller name: \(controllerName)")
                                    print("Endpoint: \(endPoint)")
                                    print("Request parameters: \(parameters)")
                                    print("Response: \(data)")
                                    print("Status code: \(statusCode)")
                                    print("------------------------RESPONSE------------------------------")
                                }
                                
                                if let err = dictionary["odata.error"] as? NSDictionary {
                                    error = err
                                }else {
                                    success = dictionary
                                }
                                completionHandler(success, error)
                            }catch let err as NSError {
                                completionHandler(nil, nil)
                                Log.shared.addLog(err: err)
                            }
                        }
                    } else {
                        if headers["X-HTTP-Method"] != nil {
                            completionHandler(["delete": true], nil)
                        } else {
                            completionHandler(nil, nil)
                        }
                    }
                    break
                }
            }
            
        }
    }
    
    //global connection manager
    //this method create a bridge between framework and Office365
    //method: HTTPMethod (mandatory)
    //resource: Resource (mandatory)
    //controllerName: String (optional)
    //endPoint: String (optional)
    //parameters: (optional=default empty value)
    //headers: [String: AnyObject] (optional)
    //@ocompletionHandler: (DataResponse<Data>)
    //method access: private
    private func beginRequest(method: HTTPMethod, resource: Resource, controllerName: String = "", endPoint: String = "", parameters: [String: AnyObject] = [:], headers: [String: AnyObject] = [:], isBinary: Data? = nil, completionHandler: @escaping(AFDataResponse<Data>)->()){
        
        var token: String = ""
        
        if let resourceToken = OGOOConfig.tokenManager[resource] {
            token = resourceToken.getToken()
        }
        
        var defaultHeaders: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        //set optional headers
        for (key, value) in headers {
            if let val = value as? String {
                defaultHeaders[key] = val
            }
        }
        
        //set parameter encoding
        //defaut: JSONEncoding.default
        var encoding: ParameterEncoding = JSONEncoding.default
        if method == .get {
            encoding = URLEncoding.default
        }
        
        //get resource url
        let resourceUrl = OGOOConfig.tokenManager[resource]!.getUrl()
        
        var url: String = resourceUrl
        
        if endPoint != "" {
            url = endPoint
        }else {
            url += "\(controllerName)"
        }
        
        if OGOOConfig.debugMode {
            print("------------------------REQUEST------------------------------")
            print("Resource: \(resource)")
            print("Headers: \(defaultHeaders)")
            print("Controller name: \(controllerName)")
            print("Endpoint: \(endPoint)")
            print("Url: \(url)")
            print("Request parameters: \(parameters)")
            print("------------------------REQUEST------------------------------")
        }
        
        if let xml = parameters["xml"] as? String {

            if let url = URL(string: url) {
                NetworkClient.shared.session.request(url, method: method, parameters: [:], encoding: xml, headers: defaultHeaders).responseData { (response) in
                    completionHandler(response)
                }
            }
        }else {
            if let binaryData = isBinary {
                NetworkClient.shared.session.upload(binaryData, to: url, method: method, headers: defaultHeaders).responseData { (response) in
                    completionHandler(response)
                }
            }else {
                NetworkClient.shared.session.request(url, method: method, parameters: parameters, encoding: encoding, headers: defaultHeaders).responseData { (response) in
                    completionHandler(response)
                }
            }
        }
    }
}

extension String: ParameterEncoding {
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
}
