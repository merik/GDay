//
//  ResultCell.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit

class ResultCell: UICollectionViewCell {

    @IBOutlet weak var resultInfoLabel: UILabel!
    @IBOutlet weak var resultImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setResult(result: Result) {
        resultInfoLabel.text = result.resultOutput
        resultImageView.image = result.image
    }
}
