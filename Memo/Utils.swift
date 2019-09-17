//
//  Utils.swift
//  Memo
//
//  Created by MC975-107 on 17/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import Foundation

extension UIViewController {
    var tutorialSB: UIStoryboard {
        return UIStoryboard(name: "Tutorial", bundle: Bundle.main)
    }
    func instanceTutorialVC(name: String) -> UIViewController? {
        return self.tutorialSB.instantiateViewController(withIdentifier: name)
    }
}
