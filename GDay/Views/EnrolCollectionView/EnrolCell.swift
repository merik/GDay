//
//  EnrolCell.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit

class EnrolCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var enrolResult: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setEnrol(enrol: Enrolment) {
        imageView.image = enrol.image
        enrolResult.text = enrol.message
    }
}
