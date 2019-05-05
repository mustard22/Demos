//
//  MyFileManager.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//

import Foundation.NSPathUtilities
import Foundation.NSFileManager

import AVFoundation

/// 文件处理
class MyFileManager: NSObject {
    
    // 文件夹名字（存放缓存文件）
    static let directory = "/MyPlayerFiles"
    
    /// 目录设置获取(.../MyPlayerFiles)
    private static func saveDirectory() -> String {
        let m = FileManager.default
        var dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        dir?.append(directory)// 拼接自定义文件夹名字
        // 创建文件夹
        if !m.fileExists(atPath: dir!) {
            try! m.createDirectory(at: URL(fileURLWithPath: dir!), withIntermediateDirectories: true, attributes: nil)
        }
        return dir!
    }
    
    /// 保存路径(无后缀'.mp4')
    static func savePath(ofUrlStr url: NSURL) -> String {
        var path = saveDirectory()
        path.append("/")
        path.append(MyFileManager.fileName(ofUrlStr: url))
        return path
    }
    
    /// 文件名字(将URL进行MD5加密)
    static func fileName(ofUrlStr url: NSURL) -> String {
        let name = (url.absoluteString?.MD5)!
        return name
    }
    
    /// 文件路径是否已存在
    static func fileExist(ofURL url: NSURL) -> Bool {
        let save_dir = saveDirectory()
        let files = try?  FileManager.default.contentsOfDirectory(atPath: save_dir)
        var isExist = false
        for str in files! {
            if str.hasPrefix(fileName(ofUrlStr: url)) {
                isExist = true
                break
            }
        }
        return isExist
    }
    
    /// 清理缓存文件
    static func cleanAllCache() {
        DispatchQueue.global().async {
            // 连同文件夹清理
            try! FileManager.default.removeItem(atPath: saveDirectory())
            DispatchQueue.main.async(execute: {
//                print("缓存清理完毕。。")
            })
        }
    }
}

extension MyFileManager {
    /// 判断是不是视频格式的链接
    private static func isVideo(ofURL url: URL) -> Bool {
        let pathExtension = url.pathExtension
        if pathExtension == "mp3" || pathExtension == "m4a" || pathExtension == "wav" {
            // 常见音频格式
        } else {
            return true
        }
        return false
    }
    /// 保存视频文件到本地
    static func saveAVAssetToLocale(ofAsset asset: AVAsset, ofURL url: NSURL) {
        let avasset: AVAsset? = asset
        if avasset == nil {
            return
        }
        // 检测文件是否已经存在
        if MyFileManager.fileExist(ofURL: url) {
            return
        }
        // 设置后缀
        let isvideo = isVideo(ofURL: url as URL)
        var pathExtension = "."
        if isvideo {
            pathExtension.append("mp4")
        } else {
            pathExtension.append("m4a")
        }
        // 设置保存路径
        var filePath: String = MyFileManager.savePath(ofUrlStr: url)
        filePath.append(pathExtension)
        // 本地文件URL
        let fileUrl: NSURL = NSURL(fileURLWithPath: filePath)
        // 写入本地
        let presetName = isvideo ? AVAssetExportPresetMediumQuality : AVAssetExportPresetAppleM4A
        let outFileType: AVFileType = isvideo ? .mp4 : .m4a
        let export = AVAssetExportSession(asset: avasset!, presetName: presetName)
        export?.outputURL = fileUrl as URL
        export?.determineCompatibleFileTypes(completionHandler: { _  in
            export?.outputFileType = outFileType
            export?.shouldOptimizeForNetworkUse = true
            export?.exportAsynchronously(completionHandler: {
                if export?.status == .failed {
                    print("file caches failed!")
                } else if export?.status == .completed {
                    print("file caches succeed!")
                }
            })
        })
    }
}
