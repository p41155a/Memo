//
//  ProfileVC.swift
//  Memo
//
//  Created by MC975-107 on 16/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let profileImage = UIImageView() // 프로필 사진
    let tv = UITableView() // 프로필 목록
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 뒤로 가기 버튼
        let backBtn = UIBarButtonItem(title: "닫기", style: .plain, target: self, action: #selector(close))
        self.navigationItem.leftBarButtonItem = backBtn
        
        // 배경 이미지 설정
        let bg = UIImage(named: "profile-bg.png")
        let bgImg = UIImageView(image: bg)
        bgImg.frame.size = CGSize(width: bgImg.frame.size.width, height: bgImg.frame.size.height)
        bgImg.center = CGPoint(x: self.view.frame.width / 2, y: 40)
        bgImg.layer.cornerRadius = bgImg.frame.size.width / 2
        bgImg.layer.borderWidth = 0
        bgImg.layer.masksToBounds = true
        self.view.addSubview(bgImg)
        self.view.bringSubviewToFront(self.tv)
        self.view.bringSubviewToFront(self.profileImage)
        
        // 프로필 사진 기본 이미지
        let image = UIImage(named: "account.jpg")
        self.profileImage.image = image
        self.profileImage.frame.size = CGSize(width: 100, height: 100)
        self.profileImage.center = CGPoint(x: self.view.frame.width / 2, y: 270)
        
        // 프로필 이미지 둥글게 마스크 처리
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.layer.borderWidth = 0
        self.profileImage.layer.masksToBounds = true
        self.view.addSubview(self.profileImage)
        
        // 테이블 뷰
        self.tv.frame = CGRect(x: 0, y: self.profileImage.frame.origin.y + self.profileImage.frame.size.height + 20, width: self.view.frame.width, height: 100)
        self.tv.dataSource = self
        self.tv.delegate = self
        
        self.view.addSubview(self.tv)
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @objc func close(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
        // 프로필 화면으로의 전환은 프레젠트 메소드 방식으로 처리될 예정(전체 화면을 덮듯이)이기 때문에 dismiss(animated:) 메소드를 사용
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "이름"
            cell.detailTextLabel?.text = "yoojin"
        case 1:
            cell.textLabel?.text = "계정"
            cell.detailTextLabel?.text = "p41155a@naver.com"
        default:
            ()
        }
        return cell
    }
}
