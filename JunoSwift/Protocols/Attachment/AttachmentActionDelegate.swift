//
//  AttachmentActionDelegate.swift
//  Juno
//
//  Created by Uğur Uğurlu on 14.02.2018.
//  Copyright © 2018 Ugur Ugurlu. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol AttachmentActionDelegate {
    
    @objc optional func attachmentActionProgress(uploadedFileCount: Int, totalFileCount: Int)
    
    @objc optional func attachmentActionProgressDone(attachment: SPAttachment, uploadedFileCount: Int)
    
    @objc optional func attachmentUploadFinished()
}
