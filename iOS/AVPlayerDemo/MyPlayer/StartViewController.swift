//
//  StartViewController.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/27.
//  Copyright © 2017年 mustard. All rights reserved.
//

import UIKit
/// 应用的开始界面
class StartViewController: ViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.m_title("StartPage")
        // 默认隐藏返回按钮
        self.backButton?.isHidden = true
        
        let click = UIButton(type: .custom)
        click.bounds = CGRect(x: 0.0, y: 0.0, width: 150.0, height: 40.0)
        click.center = self.view.center
        click.setTitle("click", for: .normal)
        click.backgroundColor = .lightGray
        click.addTarget(self, action: #selector(clickAction), for: .touchUpInside)
        self.view.addSubview(click)
        
        let click2 = UIButton(type: .custom)
        click2.frame = CGRect(x: click.m_left, y: click.m_bottom+20.0, width: click.m_width, height: click.m_height)
        click2.setTitle("cleanCache", for: .normal)
        click2.backgroundColor = .lightGray
        click2.addTarget(self, action: #selector(click2Action), for: .touchUpInside)
        self.view.addSubview(click2)
    }
    /// 点击跳转到播放界面
    @objc func clickAction() {
        let vc = MyPlayViewController(nibName: nil, bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func click2Action() {
        MyFileManager.cleanAllCache()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

