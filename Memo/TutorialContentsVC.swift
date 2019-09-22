//
//  TutorialContentsVC.swift
//  Memo
//
//  Created by MC975-107 on 17/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit

class TutorialContentsVC: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bgImageView: UIImageView!
    
    var pageIndex: Int!
    var titleText: String!
    var imageFile: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = self.titleText
        self.titleLabel.sizeToFit()
        self.bgImageView.image = UIImage(named: self.imageFile)
    }
    
}
