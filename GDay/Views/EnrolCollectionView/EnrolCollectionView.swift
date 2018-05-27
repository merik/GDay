//
//  EnrolCollectionView.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit

class EnrolCollectionView: UICollectionView {

    private let cellName = "EnrolCell"
    private let cellSize = CGSize(width: 120, height: 100)
    
    func makeNewEnrol() -> Enrollment {
        let id = enrols.count
        let enrol = Enrollment(id: id)
        return enrol
    }
    var nextUnsubmittedEnrol: Enrollment? {
        for enrol in enrols {
            if enrol.unSubmitted {
                return enrol
            }
        }
        return nil
    }
    var enrols: [Enrollment] = [Enrollment]() {
        didSet {
            reloadData()
        }
    }
    func updateEnrol(_ enrol: Enrollment) {
        var elementIndex = -1
        for (index, enr) in enrols.enumerated() {
            if enr.id == enrol.id {
                enr.message = enrol.message
                elementIndex = index
                break
            }
        }
        if elementIndex >= 0 {
            let indexPath = IndexPath(item: elementIndex, section: 0)
            self.reloadItems(at: [indexPath])
        }
    }
    func addNewResult(_ result: Enrollment) {
        enrols.append(result)
    }
    func configLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = cellSize
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionViewLayout = layout
        self.isPagingEnabled = false
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.allowsMultipleSelection = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        register(UINib(nibName: cellName, bundle: nil), forCellWithReuseIdentifier: cellName)
        self.dataSource = self
        self.delegate = self
        configLayout()
    }

}
extension EnrolCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return enrols.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath) as! EnrolCell
        cell.setEnrol(enrol: enrols[indexPath.item])
        
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}


