//
//  MyPlayer.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//
import AVFoundation
import UIKit

//MARK: 播放器状态
enum MyPlayerStatus {
    /// 准备播放
    case ReadyToPlay
    /// 播放失败
    case PlayFailed
    /// 正在缓冲
    case Buffering
    /// 正在播放
    case Playing
    /// 暂停状态
    case Paused
}

//MARK: 声明定义
class MyPlayer: NSObject {
    private var player: AVPlayer? = nil
    private var playerItem: AVPlayerItem? = nil
    private var urlAsset: AVURLAsset? = nil
    private var playerLayer: AVPlayerLayer? = nil
    
    // 是否播放本地文件（默认false）
    private var isPlaybackFile: Bool = false
    
    // 添加观察的keypath
    private let rate = "rate"
    private let status = "status"
    private let playbackBufferEmpty = "playbackBufferEmpty"
    private let playbackLikelyToKeepUp = "playbackLikelyToKeepUp"
    private let loadedTimeRanges = "loadedTimeRanges"
    
    private var url: NSURL? = nil
    // 缓存进度
    private var cacheProgress: CGFloat = 0.0
    // 播放进度
    private var play_progress: CGFloat = 0.0;
    // 当前播放时间
    private var currentTime: CGFloat = 0.0
    // 资源总时长
    private var duration: CGFloat = 0.0
    
    private var playTimer: Any? = nil
    // 播放器状态
    private var player_status: MyPlayerStatus = .PlayFailed
    var delegate: MyPlayerDelegate? = nil
    // 是否允许播放(外界控制：点击暂停或播放)
    private var isAllowPlay = false
    
    /// 播放网络视频
    init(URL: NSURL) {
        super.init()
        url = URL
        self.setupPlayer(ofURL:URL, ofLocale: false)
    }
    /// 播放本地视频文件
    init(ofFileURL path: NSURL) {
        super.init()
        url = path
        self.setupPlayer(ofURL: path, ofLocale: true)
    }
    /// 析构函数释放资源
    deinit {
        print("MyPlayer execute func : deinit")
        self.releasePlayer()
    }
}


//MARK: 外部调用
extension MyPlayer {
    /// 在外部设置播放层AVPlayerLayer（传一个承载view进来）
    func setupPlayerLayer(ofContent superView: UIView) {
        if playerLayer != nil {
            // 播放层已经初始化过了 仅仅设置frame
            playerLayer?.frame = superView.layer.bounds
            return
        }
        playerLayer = AVPlayerLayer(player: player!)
        playerLayer?.frame = superView.layer.bounds
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        superView.layer.addSublayer(playerLayer!)
    }
    /// 播放
    func play() {
        player?.play()
        self.isAllowPlay = true
        self.player_status = .Playing
        DispatchQueue.main.async {
            self.delegate?.playerStatusChanged(ofStatus: self.player_status)
        }
    }
    /// 暂停
    func pause() {
        player?.pause()
        self.isAllowPlay = false
        self.player_status = .Paused
        DispatchQueue.main.async {
            self.delegate?.playerStatusChanged(ofStatus: self.player_status)
        }
    }
    /// 重播
    func replayback() -> Void {
        player?.seek(to: kCMTimeZero)
        self.play()
    }
    /// 缓存进度(百分比)(get)
    var loadProgress: CGFloat {
        get {
            return self.cacheProgress
        }
    }
    /// 播放进度(get,set)
    var playProgress: CGFloat {
        get {
            return self.play_progress
        }
        set {
            self.play_progress = playProgress
            currentTime = self.duration * playProgress
            player?.seek(to: CMTimeMake(Int64(currentTime), Int32(1.0)))
        }
    }
    /// 当前播放时间(get)
    var playTime: CGFloat {
        get {
            return self.currentTime
        }
    }
    /// 获取资源播放的总时长(get)
    var length: CGFloat {
        get {
            return self.duration
        }
    }
    /// 获取当前播放器状态
    var playerStatus: MyPlayerStatus {
        get {
            return self.player_status
        }
    }
}


extension MyPlayer {
    /// 开始播放
    private func startPlay() {
        self.duration = CGFloat(CMTimeGetSeconds((playerItem?.duration)!))
        
        weak var wself = self
        playTimer = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1.0, Int32(1.0)), queue: DispatchQueue.global(), using: { (time: CMTime) in
            // 当前播放时间 和 播放进度
            wself?.currentTime = CGFloat(CMTimeGetSeconds(time))
            wself?.play_progress = (wself?.currentTime)!/(wself?.duration)!
        })
    }
}


extension MyPlayer {
    /// 初始化播放器(isLocale:是否本地文件)
    private func setupPlayer(ofURL url: NSURL, ofLocale isLoacle: Bool) {
        if !isLoacle {
            // 播放链接是网络资源链接
            if MyFileManager.fileExist(ofURL: url) {
                // 网络资源已经缓存到本地了
                let playUrl = NSURL(fileURLWithPath: MyFileManager.savePath(ofUrlStr: url))
                setURLAsset(ofURL: playUrl)
                // 标记播放的是文件
                isPlaybackFile = true
            }
        } else {
            isPlaybackFile = true
        }
        
        if urlAsset == nil {
            setURLAsset(ofURL: url)
        }
        
        setPlayerItem()
        
        player = AVPlayer(playerItem: playerItem!)
        player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
    }
    /// 设置AVURLAsset
    private func setURLAsset(ofURL url: NSURL) {
        urlAsset = AVURLAsset(url: url as URL)
    }
    /// 设置AVPlayerItem
    private func setPlayerItem() {
        playerItem = AVPlayerItem(asset: urlAsset!)
        playerItemAddObserver()// add observer
    }
    /// playerItem添加观察者
    private func playerItemAddObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerEndedNotification), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.addObserver(self, forKeyPath: status, options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: playbackLikelyToKeepUp, options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: playbackBufferEmpty, options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: loadedTimeRanges, options: NSKeyValueObservingOptions.new, context: nil)
    }
    /// playerItem移除所有观察者
    private func removeObserverForPlayerItem() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        playerItem?.removeObserver(self, forKeyPath: status)
        playerItem?.removeObserver(self, forKeyPath: playbackLikelyToKeepUp)
        playerItem?.removeObserver(self, forKeyPath: playbackBufferEmpty)
        playerItem?.removeObserver(self, forKeyPath: loadedTimeRanges)
    }
    // 播放完毕通知
    @objc func playerEndedNotification() {
        DispatchQueue.main.async {
            self.delegate?.playbackEnded()
        }
    }
    /// 释放播放器资源
    func releasePlayer() {
        if urlAsset != nil {
            urlAsset?.cancelLoading()
            urlAsset = nil
        }
        if(player != nil) {
            player?.removeTimeObserver(playTimer as Any)
            playTimer = nil
            
            player?.currentItem?.cancelPendingSeeks()
            player?.currentItem?.asset.cancelLoading()
            player?.replaceCurrentItem(with: nil)
            player?.pause()
            player?.removeObserver(self, forKeyPath: rate)
            player = nil
        }
        if playerItem != nil {
            self.removeObserverForPlayerItem()
            playerItem = nil
        }
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == status {
            if playerItem?.status == AVPlayerItemStatus.readyToPlay {
                self.player_status = .ReadyToPlay;
                self.startPlay()// 准备播放
            } else {
                // 加载失败
                self.player_status = MyPlayerStatus.PlayFailed
            }
            DispatchQueue.main.async {
                self.delegate?.playerStatusChanged(ofStatus: self.player_status)
            }
        }
        else if keyPath == playbackLikelyToKeepUp {
            // 有缓存可以播放了 播放
            if isAllowPlay {
                self.player?.play()
                self.player_status = MyPlayerStatus.Playing
                DispatchQueue.main.async {
                    self.delegate?.playerStatusChanged(ofStatus: self.player_status)
                }
            }
        }
        else if keyPath == playbackBufferEmpty {
            // 没有缓存可以播放 缓冲
            self.player?.pause()// pause
            self.player_status = MyPlayerStatus.Buffering
            DispatchQueue.main.async {
                self.delegate?.playerStatusChanged(ofStatus: self.player_status)
            }
        }
        else if keyPath == loadedTimeRanges {
            // 设置缓存
            if isPlaybackFile {
                cacheProgress = 1.0
            } else {
                caculateCacheProgress()
            }
            DispatchQueue.main.async {
                self.delegate?.playerCacheProgressChanged(ofCache: Float(self.cacheProgress))
            }
        }
        else if keyPath == rate {
            // 播放器速率变化
        }
    }
    /// 计算缓存
    private func caculateCacheProgress() {
        let ranges = playerItem?.loadedTimeRanges
        let timeRange = (ranges?.first)! as! CMTimeRange
        let cacheTime = CGFloat(CMTimeGetSeconds(timeRange.start)) + CGFloat(CMTimeGetSeconds(timeRange.duration))
        
        self.cacheProgress = cacheTime/self.duration
        /// 异步缓存文件到本地
        DispatchQueue.global().async {
            if self.cacheProgress == 1.0 {
                // 缓存文件
                DispatchQueue.global().async(execute: {
                    MyFileManager.saveAVAssetToLocale(ofAsset: (self.playerItem?.asset)!, ofURL: self.url!)
                })
            }
        }
        
    }
}
