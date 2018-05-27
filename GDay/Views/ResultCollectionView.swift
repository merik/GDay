//
//  ResultCollectionView.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit

class ResultCollectionView: UICollectionView {

    private let cellName = "ResultCell"
    private let cellSize = CGSize(width: 120, height: 100)
    
    var results: [Result] = [Result]() {
        didSet {
            reloadData()
        }
    }
    func addNewResult(_ result: Result) {
        results.append(result)
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
extension ResultCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath) as! ResultCell
        cell.setResult(result: results[indexPath.item])
        
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

