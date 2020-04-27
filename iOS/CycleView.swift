//
//  CycleView.swift
//  Myblog
//
//  Created by MAC on 2020/4/26.
//  Copyright © 2020 MAC. All rights reserved.
//
/** 使用方式：
 initial:
 let cv = CycleView(frame: .zero, allowAutoScroll: true, scrollDirection: .left, showType: .onlyImage)
 
 refresh:
 cv.refresh(images: ["1.png", "2.png"], words: [], placeHolder: nil)
 
 */

import UIKit

//MARK: - Enum: 轮播图显示类型
public enum CycleType {
    /// 纯图片
    case onlyImage
    /// 纯文字
    case onlyWord
    /// 图片+文字
    case imageAndWord
}

//MARK: - Enum: 轮播图（自动）滚动方向
public enum CycleScrollDirection {
    /// 向左
    case left
    /// 向右
    case right
    /// 向上
    case up
    /// 向下
    case down
    
    var collectionDirection: UICollectionView.ScrollDirection {
        switch self {
        case .left, .right:
            return .horizontal
        default:
            return .vertical
        }
    }
}


//MARK: - class: CycleView
class CycleView: UIView {
    
    private var originalData: [CycleItem] = []
    
    private var dataSource: [CycleItem] = []
    
    private var currentPath: IndexPath = IndexPath(row: 1, section: 0)
    
    private var showType: CycleType = .onlyImage
    
    private var timer: Timer?
    
    /// 默认允许自动滚动
    private var allowAutoScroll: Bool = true
    
    
    /// 自动滚动间隔
    public var timerDuration: TimeInterval = 3.0
    
    public var didselectHandler: ((_ index: Int)->Void)?
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 0
        l.minimumLineSpacing = 0
        l.itemSize = bounds.size
        l.scrollDirection = self.scrollDirection.collectionDirection
        return l
    }()
    
    private lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: bounds, collectionViewLayout: self.layout)
        v.delegate = self
        v.dataSource = self
        
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        
        v.isPagingEnabled = true
        
        v.register(CycleViewCell.self, forCellWithReuseIdentifier: "CycleViewCell")
        
        self.addSubview(v)
        return v
    }()
    
    lazy var pageControl: UIPageControl = {
        let v = UIPageControl()
        v.frame = CGRect(x: 0, y: bounds.height - 30, width: bounds.width, height: 30)
        v.currentPage = 0
        v.numberOfPages = 0
        v.hidesForSinglePage = true
        self.addSubview(v)
        return v
    }()
    
    private var scrollDirection: CycleScrollDirection = .left

    init(frame: CGRect, allowAutoScroll: Bool = true, scrollDirection: CycleScrollDirection = .left, showType: CycleType = .onlyImage) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.allowAutoScroll = allowAutoScroll
        self.scrollDirection = scrollDirection
        self.showType = showType
    }
    
    deinit {
        self.stopTimer()
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: Set up for CycleView
extension CycleView {
    
    public func refresh(images: [Any] = [], words: [String] = [], placeHolder: UIImage? = nil) {
        self.setupOriginalData(images, words, placeHolder)
        
        self.setupDataSource()
        
        if originalData.isEmpty {
            return
        }
        
        self.setStartPosition()
        self.setupPageControl()
        self.startTimer()
        
    }
    
    private func setupPageControl() {
        pageControl.numberOfPages = originalData.count
        pageControl.currentPage = 0
    }
    
    private func setupOriginalData(_ imgs: [Any], _ words: [String], _ placeHolder: UIImage? = nil) {
        
        switch self.showType {
        case .onlyImage:
            originalData = imgs.map({ (i) -> CycleItem in
                var m = CycleItem(type: self.showType)
                if let image = i as? UIImage {
                    m.image = image
                } else if let url = i as? String {
                    m.placeHolder = placeHolder
                    if url.hasPrefix("http") {
                        m.imgUrl = URL(string: url)
                    } else {
                        m.image = UIImage(named: url)
                    }
                }
                return m
            })
        case .onlyWord:
            originalData = words.map({ (w) -> CycleItem in
                return CycleItem(title: w, type: self.showType)
            })
        case .imageAndWord:
            originalData = imgs.map({ (i) -> CycleItem in
                var m = CycleItem(type: self.showType)
                if let image = i as? UIImage {
                    m.image = image
                } else if let url = i as? String {
                    m.placeHolder = placeHolder
                    if url.hasPrefix("http") {
                        m.imgUrl = URL(string: url)
                    } else {
                        m.image = UIImage(named: url)
                    }
                }
                return m
            })
            
            for (i, w) in words.enumerated() {
                originalData[i].title = w
            }
        }
    }
    
    private func setupDataSource() {
        dataSource.removeAll()
        if originalData.isEmpty {
            return
        }
        
        let start = originalData.last!
        let end = originalData.first!
        
        let tmp = [start] + originalData + [end]
        dataSource = tmp
    }
    
    private func setStartPosition() {
        var offset = CGPoint.zero
        switch self.scrollDirection {
        case .left, .right:
            offset.x = collectionView.bounds.size.width
        default:
            offset.y = collectionView.bounds.size.height
        }
        
        self.setupOffset(offset, false)
    }
    
    private func setupOffset(_ offset: CGPoint, _ animated: Bool) {
        collectionView.setContentOffset(offset, animated: animated)
    }
    
    private func setEndPosition() {
        var offset = CGPoint.zero
        switch self.scrollDirection {
        case .left, .right:
            offset.x = collectionView.bounds.size.width *  CGFloat(dataSource.count-2)
        default:
            offset.y = collectionView.bounds.size.height * CGFloat(dataSource.count-2)
        }
        
        self.setupOffset(offset, false)
    }
}

//MARK: Timer
extension CycleView {
    private func startTimer() {
        if self.allowAutoScroll == false {
            return
        }
        
        stopTimer()
        
        timer = Timer(timeInterval: self.timerDuration, repeats: true, block: {[weak self] (t) in
            self?.timerAction()
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        if let _ = timer {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func timerAction() {
        var offset = collectionView.contentOffset
        switch self.scrollDirection {
        case .up:
            offset.y += collectionView.frame.size.height
        case .down:
            offset.y -= collectionView.frame.size.height
        case .left:
            offset.x += collectionView.frame.size.width
        case .right:
            offset.x -= collectionView.frame.size.width
        }
        
        self.setupOffset(offset, true)
    }
}


//MARK: UICollectionViewDelegate
extension CycleView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CycleViewCell", for: indexPath) as! CycleViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell0 = cell as! CycleViewCell
        
        self.currentPath = indexPath
        self.pageControl.currentPage = self.index(with: indexPath)
        
        let item = self.dataSource[indexPath.row]
        cell0.titleLabel.text = "\(item.title ?? "")"
        cell0.contentView.backgroundColor = UIColor.rand()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ind = self.index(with: indexPath)
        
        print("didselect item index is: \(ind)\n current offset is: \(collectionView.contentOffset)")
        
        self.didselectHandler?(ind)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.stopTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.x >= (bounds.width  *  CGFloat(images.count - 1)) {
//            self.setStartPosition()
//        }
//        else if scrollView.contentOffset.x <= 0 {
//            self.setEndPosition()
//        }
        
        self.startTimer()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        switch self.scrollDirection {
        case .left, .right:
            if offset.x >= (scrollView.bounds.width  *  CGFloat(dataSource.count - 1)) {
                self.setStartPosition()
            }
            else if offset.x <= 0 {
                self.setEndPosition()
            }
        case .up, .down:
            if offset.y >= (scrollView.bounds.height  *  CGFloat(dataSource.count - 1)) {
                self.setStartPosition()
            }
            else if offset.y <= 0 {
                self.setEndPosition()
            }
        }
    }

    //MARK: 通过collectionView的indexPath，找到对应的原数据下标
    private func index(with indexPath: IndexPath) -> Int {
        var ind = 0
        if indexPath.row == 0 {
            ind = self.originalData.count - 1
        } else if indexPath.row == self.dataSource.count - 1 {
            ind = 0
        } else {
            ind = indexPath.row - 1
        }

        return ind
    }
}


//MARK: - class: CycleViewCell
class CycleViewCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.boldSystemFont(ofSize: 60)
        v.textAlignment = .center
        v.textColor = .white
        contentView.addSubview(v)
        return v
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.frame = contentView.bounds
    }
}

//MARK: - struct: cell item
struct CycleItem {
    var image: UIImage?
    
    var imgUrl: URL?
    var placeHolder: UIImage?
    
    var title: String?
    
    var type: CycleType = .onlyImage
}



//class CycleScroll: UIView {
//    private var direction: CycleScrollDirection = .left
//    private lazy var scroll: UIScrollView = {
//        let v = UIScrollView()
//        v.frame = bounds
//        v.contentInsetAdjustmentBehavior = .never
//        v.isPagingEnabled = true
//        v.showsVerticalScrollIndicator = false
//        v.showsHorizontalScrollIndicator = false
//        self.addSubview(v)
//        return v
//    }()
//}
