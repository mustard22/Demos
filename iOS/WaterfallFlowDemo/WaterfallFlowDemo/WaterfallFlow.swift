//
//  WaterfallFlow.swift
//  WaterfallFlowDemo
//
//  Created by walker on 2019/5/5.
//  Copyright © 2019 walker. All rights reserved.
//

import Foundation
import UIKit

//MARK: WaterFlowLayoutProtocol
@objc protocol WaterFlowLayoutProtocol: NSObjectProtocol {
    /// 每个item的高度
    func waterFallLayout(waterFallLayout: WaterfallFlowLayout, heightForItemAtIndexPath indexPath: Int, itemWidth: CGFloat) -> CGFloat
    
    /// 有多少列
    @objc optional func columnCountInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> Int
    
    /// 每列之间的间距
    @objc optional func columnMarginInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> CGFloat
    
    /// 每行之间的间距
    @objc optional func rowMarginInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> CGFloat
    
    /// 每个item的内边距
    @objc optional func edgeInsetdInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> UIEdgeInsets
}

//MARK: WaterfallFlowLayout
class WaterfallFlowLayout: UICollectionViewFlowLayout {
    // 相关默认值
    private let colCount = 3
    private let colMargin: CGFloat = 5.0
    private let rowMargin: CGFloat = 5.0
    private let edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    /** 存放所有的布局属性 */
    private lazy var attrsArr: [UICollectionViewLayoutAttributes] = []
    /** 存放所有列的当前高度 */
    private lazy var columnHeights: [CGFloat] = []
    /** 内容的高度 */
    private var contentHeight: CGFloat = 0
    
    weak var delegate: WaterFlowLayoutProtocol?
    
}

// private funcs
extension WaterfallFlowLayout {
    // 列数
    private func getColumnCount() -> Int {
        if let _ = delegate, delegate!.responds(to: #selector(WaterFlowLayoutProtocol.columnCountInWaterFallLayout(waterFallLayout:))) {
            return delegate!.columnCountInWaterFallLayout!(waterFallLayout: self)
        } else {
            return colCount
        }
    }
    
    // 列间距
    private func getColumnMargin() -> CGFloat {
        if let _ = delegate, delegate!.responds(to: #selector(WaterFlowLayoutProtocol.columnMarginInWaterFallLayout(waterFallLayout:))) {
            return delegate!.columnMarginInWaterFallLayout!(waterFallLayout: self)
        } else {
            return colMargin
        }
    }
    
    // 行间距
    private func getRowMargin() -> CGFloat {
        if let _ = delegate, delegate!.responds(to: #selector(WaterFlowLayoutProtocol.rowMarginInWaterFallLayout(waterFallLayout:))) {
            return delegate!.rowMarginInWaterFallLayout!(waterFallLayout: self)
        } else {
            return rowMargin
        }
    }
    
    // 内边距
    private func getEdgeInsets() -> UIEdgeInsets {
        if let _ = delegate, delegate!.responds(to: #selector(WaterFlowLayoutProtocol.edgeInsetdInWaterFallLayout(waterFallLayout:))) {
            return delegate!.edgeInsetdInWaterFallLayout!(waterFallLayout: self)
        } else {
            return edgeInsets
        }
    }
}

// override funcs
extension WaterfallFlowLayout {
    override func prepare() {
         super.prepare()
        
        contentHeight = 0
        
        // 清楚之前计算的所有高度
        columnHeights.removeAll()
        
        // 设置每一列默认的高度
        for _ in 0..<self.getColumnCount() {
            columnHeights.append(edgeInsets.top)
        }
        
        // 清楚之前所有的布局属性
        attrsArr.removeAll()
        
        // 开始创建每一个cell对应的布局属性
        let count: Int = self.collectionView?.numberOfItems(inSection: 0) ?? 0
        for i in 0..<count {
            // 创建位置
            let indexPath = NSIndexPath(item: i, section: 0)
            // 获取indexPath位置上cell对应的布局属性
            let attrs = self.layoutAttributesForItem(at: indexPath as IndexPath)
            if let at = attrs {
                attrsArr.append(at)
            }
        }
    }
    
    /// 返回indexPath位置cell对应的布局属性
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // 创建布局属性
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)//[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        // collectionView的宽度
        let collectionViewW = self.collectionView!.frame.size.width
        
        // 设置布局属性的frame
        let cellW = (collectionViewW - self.getEdgeInsets().left - self.getEdgeInsets().right - CGFloat(self.getColumnCount() - 1) * self.getColumnMargin()) / CGFloat(self.getColumnCount())
        let cellH = delegate?.waterFallLayout(waterFallLayout: self, heightForItemAtIndexPath: indexPath.item, itemWidth: cellW)//[self.delegate waterFallLayout:self heightForItemAtIndexPath:indexPath.item itemWidth:cellW];
        
        // 找出最短的那一列
        var destColumn = 0
        var minColumnHeight = columnHeights[0]
        
        for i in 1..<self.getColumnCount() {
            // 取得第i列的高度
            let columnHeight = columnHeights[i]
            if (minColumnHeight > columnHeight) {
                minColumnHeight = columnHeight;
                destColumn = i;
            }
        }
        
        let cellX = self.getEdgeInsets().left + CGFloat(destColumn) * (cellW + self.getColumnMargin())
        var cellY = minColumnHeight
        if cellY != self.getEdgeInsets().top {
            cellY += self.getRowMargin()
        }
        
        attrs.frame = CGRect(x: cellX, y: cellY, width: cellW, height: cellH!)
        
        // 更新最短那一列的高度
        columnHeights[destColumn] = attrs.frame.maxY
        
        // 记录内容的高度 - 即最长那一列的高度
        let maxColumnHeight = columnHeights[destColumn]
        if (contentHeight < maxColumnHeight) {
            contentHeight = maxColumnHeight;
        }
        return attrs;
    }
    
    /// 决定cell的高度
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.attrsArr;
    }
    
    /// 内容的高度
    override var collectionViewContentSize: CGSize {
        get {
            return CGSize(width: 0, height: contentHeight + edgeInsets.bottom)
        }
    }
}

