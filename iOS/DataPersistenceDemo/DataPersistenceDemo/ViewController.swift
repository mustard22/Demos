//
//  ViewController.swift
//  DataPersistenceDemo
//
//  Created by walker on 2019/4/22.
//  Copyright © 2019 walker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "数据持久化记录"
        
        // Do any additional setup after loading the view.
        let textview = UITextView(frame: self.view.bounds)
        textview.font = .systemFont(ofSize: 20)
        textview.isEditable = false
        textview.alwaysBounceVertical = true
        self.view.addSubview(textview)
        
        textview.text = "该工程主要用于iOS数据持久化的学习记录，以代码段的形式进行演示。后续更新。。。"
    }

}

