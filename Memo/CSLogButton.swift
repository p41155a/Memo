//
//  CSLogButton.swift
//  Memo
//
//  Created by MC975-107 on 15/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit
public enum CSLogType: Int {
    case basic
    case title
    case tag
}
public class CSLogButton: UIButton {
    // 로그 출력 타입
    public var logType: CSLogType = .basic
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setBackgroundImage(UIImage(named: "button-bg"), for: .normal)
        self.tintColor = UIColor.white
        self.addTarget(self, action: #selector(logging(_:)), for: .touchUpInside)
    }
    // 로그를 출력하는 액션 메소드
    @objc func logging(_ sender: UIButton) {
        switch self.logType {
        case .basic: // 단순히 로그만 출력
            NSLog("버튼이 클릭되었습니다.")
        case .title: // 로그에 버튼의 타이틀을 출력
            let btnTitle = sender.titleLabel?.text ?? "타이틀 없는"
            NSLog("\(btnTitle) 버튼이 클릭되었습니다.")
        case .tag: // 로그에 버튼의 태그를 출력함
            NSLog("\(sender.tag) 버튼이 클릭되었습니다.")
        }
    }
}
