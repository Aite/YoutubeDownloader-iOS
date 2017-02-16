//
//  StorageManager.swift
//  PhotoCrypt
//
//  Created by Alaa Al-Zaibak on 21/11/15.
//  Copyright © 2015 Alaa Al-Zaibak. All rights reserved.
//

import Foundation
//import IDZSwiftCommonCrypto

open class StorageManager : NSObject, URLSessionDownloadDelegate {

    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!

    fileprivate static let instance : StorageManager = StorageManager()
    open class var `default`: StorageManager {
        get {
            return instance
        }
    }
    
    fileprivate override init () {
        super.init()
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: .main)
//        progressView.setProgress(0.0, animated: false)
    }
    
    fileprivate static let encryptionEnabled = true
    
    let documentsPath : NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first! as NSString
    
    func folderExists(at path: String) -> Bool {
        var directory : ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &directory)
        return exists && directory.boolValue
    }
    
    func createDirectory(_ path: String) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
    
    func renameDirectory(from sourcePath: String, to destinationPath: String) throws {
        try FileManager.default.moveItem(atPath: sourcePath, toPath: destinationPath)
    }
    
    func deleteDirectory(_ path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
    
    func deleteFile(_ path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
    
    open func writeFileAtPath (_ path: String, content: Data) -> Bool {
        NSLog("writing file at path: %@", path)
        var encryptedContent : Data? = nil
        if (StorageManager.encryptionEnabled) {
            encryptedContent = self.encrypt(content)
        }
        else {
            encryptedContent = content
        }
        
        if encryptedContent == nil {
            return false
        }

        return FileManager.default.createFile(atPath: path, contents: encryptedContent!, attributes: nil)
    }
    
    open func readFileAtPath (_ path: String) -> Data? {
        if (!FileManager.default.fileExists(atPath: path)) {
            return nil
        }
        let fileData = try? Data(contentsOf: URL(fileURLWithPath: path))
        if fileData == nil {
            return nil
        }
        else {
            if (StorageManager.encryptionEnabled) {
                return self.decrypt(fileData!)
            }
            else {
                return fileData
            }
        }
    }
    
    open func download(url sourceUrl: URL, to filePath: String) -> Void {
        downloadTask = backgroundSession.downloadTask(with: sourceUrl)
        downloadTask.resume()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }

    fileprivate func encrypt (_ data : Data) -> Data? {
//        if let cryptorSettings = UserSettings.default.cryptorSettings() {
//            return data.aesEncrypt(cryptorSettings)
//        }
        return nil
    }
    
    fileprivate func decrypt (_ data : Data) -> Data? {
//        if let cryptorSettings = UserSettings.default.cryptorSettings() {
//            return data.aesDecrypt(cryptorSettings)
//        }
        return nil
    }
}
