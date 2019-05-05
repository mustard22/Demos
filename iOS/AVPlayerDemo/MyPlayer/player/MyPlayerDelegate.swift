//
//  MyPlayerDelegate.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//
import Foundation

//MARK: 播放器代理协议
protocol MyPlayerDelegate {
    /// 缓存情况
    func playerCacheProgressChanged(ofCache progress: Float)
    /// 播放器状态发生改变
    func playerStatusChanged(ofStatus status: MyPlayerStatus)
    /// 资源播放完毕
    func playbackEnded()
}
