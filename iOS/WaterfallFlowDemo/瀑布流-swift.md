#  Swift实现瀑布流
## ViewController.swift
````
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

    // 设置collectionView
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

    // 行间距
    func rowMarginInWaterFallLayout(waterFallLayout: WaterfallFlowLayout) -> CGFloat {
        return 10.0
    }

    // 列间距
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
}

````

---

## WaterfallFlowLayout.swift
````
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

    // 存放所有的布局属性
    private lazy var attrsArr: [UICollectionViewLayoutAttributes] = []
    
    // 存放所有列的当前高度
    private lazy var columnHeights: [CGFloat] = []
    
    // 内容的高度
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
        let cellH = delegate?.waterFallLayout(waterFallLayout: self, heightForItemAtIndexPath: indexPath.item, itemWidth: cellW)//[self.delegate waterFallLayout:self heightForItemAtIndexPath:indexPath.item itemWidth:cellW]

        // 找出最短的那一列
        var destColumn = 0
        var minColumnHeight = columnHeights[0]

        for i in 1..<self.getColumnCount() {
            // 取得第i列的高度
            let columnHeight = columnHeights[i]
            if (minColumnHeight > columnHeight) {
                minColumnHeight = columnHeight
                destColumn = i
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


````


---


## WaterFlowCell.swift
````
import UIKit

class WaterFlowCell: UICollectionViewCell {
    public lazy var titleLabel = UILabel.init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.frame = self.contentView.bounds
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        self.contentView.addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

````
