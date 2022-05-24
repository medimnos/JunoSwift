//
//  SSLPinning.swift
//  OGOOSwift
//
//  Created by Uğur Uğurlu on 14.10.2021.
//

//import Foundation
//import TrustKit
//
//public final class SSLPinning {
//    public static let shared = SSLPinning()
//    private init() {}
//    
//    public func execute() {
//        TrustKit.setLoggerBlock { (message) in
//            print("TrustKit log: \(message)")
//        }
//        
//        let trustKitConfig = [
//            kTSKSwizzleNetworkDelegates: false,
//            kTSKPinnedDomains: [
//                OGOOConfig.SHAREPOINT_HOSTNAME: [
//                    kTSKEnforcePinning: true,
//                    kTSKIncludeSubdomains: true,
//                    kTSKPublicKeyHashes: [
//                        OGOOConfig.SP_SHA256_1,
//                        OGOOConfig.SP_SHA256_2,
//                        OGOOConfig.SP_SHA256_3
//                    ]
//                ],
//                OGOOConfig.GRAPH_HOSTNAME: [
//                    kTSKEnforcePinning: true,
//                    kTSKIncludeSubdomains: true,
//                    kTSKPublicKeyHashes: [
//                        OGOOConfig.GRAPH_SHA256_1,
//                        OGOOConfig.GRAPH_SHA256_2,
//                        OGOOConfig.GRAPH_SHA256_3
//                    ]
//                ],
//                OGOOConfig.AZURE_HOSTNAME: [
//                    kTSKEnforcePinning: true,
//                    kTSKIncludeSubdomains: true,
//                    kTSKPublicKeyHashes: [
//                        OGOOConfig.AZURE_SHA256_1,
//                        OGOOConfig.AZURE_SHA256_2,
//                        OGOOConfig.AZURE_SHA256_3
//                    ]
//                ]
//            ]
//        ] as [String : Any]
//        
//        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
//    }
//}
