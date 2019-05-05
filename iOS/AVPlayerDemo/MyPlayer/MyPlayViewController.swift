//
//  MyPlayViewController.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/29.
//  Copyright © 2017年 mustard. All rights reserved.
//

import UIKit

/// 播放界面
class MyPlayViewController: ViewController {

    var playView: UIView? = nil
    var playBtn: UIButton? = nil
    let playRect: CGRect = CGRect(x: 0.0, y: 64.0, width: UIScreen.main.bounds.size.width, height: 200.0)
    
    var player: MyPlayer? = nil
    /// 播放链接
    let urlStr: String = "https://cms.wj411.com/preview/upload/advertise_video/201702222245447145.mp4"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.m_title("PlayPage")
        self.initPlayView(playRect)
        self.addPlayButton(CGRect(x: (self.view.m_width-120.0)/2, y: self.view.m_height-40.0-60.0, width: 120.0, height: 40.0))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if playView != nil {
            if isLandspace() {
                playView?.frame = self.view.bounds
            } else {
                playView?.frame = playRect
            }
            if player != nil {
                player?.setupPlayerLayer(ofContent: playView!)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMyPlayer()
    }
    
    override func backButtonAction(_ sender: UIButton) {
        super.backButtonAction(backButton!)
        player = nil
    }
    
    func isLandspace() -> Bool {
        let width = UIScreen.main.bounds.size.width
        if width == max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) {
            return true
        }
        return false
    }
    
    deinit {
    }
}

//MARK: 播放器代理
extension MyPlayViewController: MyPlayerDelegate {
    func playerCacheProgressChanged(ofCache progress: Float) {
        print("缓存：\(progress)")
    }
    
    func playerStatusChanged(ofStatus status: MyPlayerStatus) {
        if status == .ReadyToPlay {
            playBtn?.isEnabled = true
            print("播放器准备好了...")
        } else if status == .PlayFailed {
            print("加载失败...")
        } else if status == .Buffering {
            playBtn?.isSelected = false
            print("正在缓冲...")
        } else if status == .Paused {
            playBtn?.isSelected = false
        } else if status == .Playing {
            playBtn?.isSelected = true
        }
    }
    
    func playbackEnded() {
        print("播放完了...")
        playBtn?.isSelected = false
    }
    
}

extension MyPlayViewController {
    /// play view
    func initPlayView(_ frame: CGRect) {
        playView = UIView(frame: frame)
        playView?.backgroundColor = UIColor.black
        self.view.addSubview(playView!)
    }
    /// play button
    func addPlayButton(_ rect: CGRect) -> Void {
        playBtn = UIButton(type: .custom)
        playBtn?.frame = rect
        playBtn?.setTitle("play", for: .normal)
        playBtn?.setTitle("pause", for: .selected)
        playBtn?.backgroundColor = UIColor.lightGray
        playBtn?.addTarget(self, action: #selector(playButtonAction(_:)), for: .touchUpInside)
        self.view.addSubview(playBtn!)
        playBtn?.isEnabled = false
    }
    // click play button
    @objc func playButtonAction(_ sender: UIButton) -> Void {
        playBtn?.isSelected = !sender.isSelected
        if (playBtn?.isSelected)! {
            player?.play()
        } else {
            player?.pause()
        }
    }
    /// 初始化播放器
    func setupMyPlayer() {
        player = MyPlayer(URL: NSURL(string: urlStr)!)
        player?.delegate = self
        player?.setupPlayerLayer(ofContent: playView!)
    }
}
