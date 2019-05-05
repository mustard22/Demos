//
//  ViewController.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/27.
//  Copyright © 2017年 mustard. All rights reserved.
//

import UIKit
/// 基类viewController
class ViewController: UIViewController {
    let topbarHeight:CGFloat = 64.0
    var titleLabel:UILabel?
    var topbar:UIView?
    var backButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = .white
        setupTopbar()
        self.addGesture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension ViewController {
    /// 设置顶部工具栏
    func setupTopbar() {
        topbar = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.m_width, height: topbarHeight))
        topbar?.backgroundColor = .white
        self.view.addSubview(topbar!)
        
        let backBtn = UIButton(type: UIButtonType.custom)
        backBtn.frame = CGRect(x: 0, y: 20.0, width: 44.0, height: 44.0)
        backBtn.addTarget(self, action: #selector(backButtonAction(_:)), for: UIControlEvents.touchUpInside)
        topbar?.addSubview(backBtn)
        backButton = backBtn
        
        let backImg = UIImageView(frame: CGRect(x: 12.0, y: 12.0, width: 20.0, height: 20.0))
        backImg.image = UIImage(named: "返回_黑色.png")
        backBtn.addSubview(backImg)
        
        titleLabel = UILabel(frame: CGRect(x: 64.0, y: 20.0, width: (topbar?.m_width)!-64.0*2, height: topbarHeight-20.0))
        titleLabel?.font = UIFont.systemFont(ofSize: 20.0)
        titleLabel?.textColor = UIColor.black
        titleLabel?.textAlignment = NSTextAlignment.center
        topbar?.addSubview(titleLabel!)
        
        let sepline = UIImageView(frame: CGRect(x: 0.0, y: (topbar?.m_bottom)!-1.0, width: (topbar?.m_width)!, height: 1.0))
        sepline.image = UIImage(named: "列表分割线.png")
        topbar?.addSubview(sepline)
    }
    
    @objc func backButtonAction(_ sender: UIButton) {
        if (self.navigationController?.viewControllers.count)! > 1 {
          self.navigationController?.popViewController(animated: true)
        }
    }
    /// 设置标题
    public func m_title(_ m_title: String) {
        self.titleLabel?.text = m_title
    }
    /// 添加手势
    func addGesture() {
        // 右划手势
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(doRightSwipeGesture))
        rightSwipe.direction = .right
        self.view.addGestureRecognizer(rightSwipe)
    }
    
    @objc func doRightSwipeGesture() {
        self.backButtonAction(backButton!)
    }
}
