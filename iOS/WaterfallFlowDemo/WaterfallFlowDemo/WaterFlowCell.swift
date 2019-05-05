//
//  WaterFlowCell.swift
//  WaterfallFlowDemo
//
//  Created by walker on 2019/5/5.
//  Copyright © 2019 walker. All rights reserved.
//

import Foundation
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
