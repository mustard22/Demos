//
//  ViewController.swift
//  WaterfallFlowDemo
//
//  Created by walker on 2019/5/4.
//  Copyright © 2019 walker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var layout: WaterfallFlowLayout?
    var collectionView: UICollectionView?
    
    let identifier = "WaterFlowCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCollectionView()
    }

    func setupCollectionView() {
        layout = WaterfallFlowLayout.init()
        layout?.delegate = self
        
        collectionView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: layout!)
        collectionView?.backgroundColor = .white
        collectionView?.dataSource = self
        collectionView?.register(WaterFlowCell.self, forCellWithReuseIdentifier: identifier)
        self.view.addSubview(collectionView!)
    }
}

//MARK: WaterFlowLayoutProtocol
extension ViewController: WaterFlowLayoutProtocol {
    // 计算item高度（随机数）
    func waterFallLayout(waterFallLayout: WaterfallFlowLayout, heightForItemAtIndexPath indexPath: Int, itemWidth: CGFloat) -> CGFloat {
        return CGFloat(arc4random_uniform(200) + 50)
    }
    
    // 自定义列数
    func columnCountInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> Int {
        return 2
    }
    
    func rowMarginInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> CGFloat {
        return 10.0
    }
    
    func columnMarginInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> CGFloat {
        return 10.0
    }
}

//MARK: UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    // 设置item个数
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! WaterFlowCell
        cell.contentView.backgroundColor = .randomColor
        cell.titleLabel.text = "\(indexPath.item)"
        return cell
    }
}

//MARK: UIColor's extension
public extension UIColor {
    /// random color(随机颜色)
    class var randomColor: UIColor {
        get {
            return UIColor(red: CGFloat(arc4random_uniform(255))/255.0, green: CGFloat(arc4random_uniform(255))/255.0, blue: CGFloat(arc4random_uniform(255))/255.0, alpha: 1.0)
        }
    }
    
    class func rgb_color(rgb: (Double,Double,Double)) -> UIColor {
        return UIColor.init(red: CGFloat(rgb.0/255.0), green: CGFloat(rgb.1/255.0), blue: CGFloat(rgb.2/255.0), alpha: 1.0)
    }
    
    class func rgba_color(rgba: (Double,Double,Double,Double)) -> UIColor {
        return UIColor.init(red: CGFloat(rgba.0/255.0), green: CGFloat(rgba.1/255.0), blue: CGFloat(rgba.2/255.0), alpha: CGFloat(rgba.3))
    }
}
