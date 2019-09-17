//
//  SideBarVC.swift
//  Memo
//
//  Created by MC975-107 on 16/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit

class SideBarVC: UITableViewController {
    let nameLabel = UILabel() // 이름
    let emailLabel = UILabel() // 이메일
    let profileImage = UIImageView() // 프로필 이미지
    
    let uinfo = UserInfoManager()
    
    // 목록 데이터
    let titles = ["새글 작성하기", "친구 새글", "달력으로 보기", "공지사항", "통계", "계정 관리"]
    
    //  아이콘
    let icons = [UIImage(named: "icon01"),
                 UIImage(named: "icon02"),
                 UIImage(named: "icon03"),
                 UIImage(named: "icon04"),
                 UIImage(named: "icon05"),
                 UIImage(named: "icon06")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 테이블 뷰의 헤더 역할을 할 뷰
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 70))
        headerView.backgroundColor = .brown
        self.tableView.tableHeaderView = headerView
        
        // 이름 레이블
        self.nameLabel.frame = CGRect(x: 70, y: 15, width: 100, height: 30)
        self.nameLabel.textColor = .white
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        self.nameLabel.backgroundColor = .clear
        headerView.addSubview(self.nameLabel)
        
        // 이메일
        self.emailLabel.frame = CGRect(x: 70, y: 30, width: 130, height: 30)
        self.emailLabel.font = UIFont.systemFont(ofSize: 11)
        self.emailLabel.backgroundColor = .clear
        headerView.addSubview(self.emailLabel)
        
        // 기본 프로필 이미지 구현
        self.profileImage.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        view.addSubview(self.profileImage)
        // 프로필 이미지 둥글게 처리
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2 // 반원 형태
        self.profileImage.layer.borderWidth = 0 // 테두리 두께
        self.profileImage.layer.masksToBounds = true // 마스크 효과
        view.addSubview(self.profileImage)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "menucell" // 테이블 셀 식별자
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .default, reuseIdentifier: id)
        
        // 테이블과 이미지를 대입
        cell.textLabel?.text = self.titles[indexPath.row]
        cell.imageView?.image = self.icons[indexPath.row]
        
        // 폰트
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 새글 작성 메뉴 일 때
        if indexPath.row == 0 {
            let uv = self.storyboard?.instantiateViewController(withIdentifier: "MemoForm")
            let target = self.revealViewController()?.frontViewController as! UINavigationController
            target.pushViewController(uv!, animated: true)
            self.revealViewController()?.revealToggle(self) // 사이드 바 닫아주는 메소드
            // SWRevealViewContoller에 정의되어 있기 때문에 revealViewController() 메소드를 통해 메인 컨트롤러의 참조 정보를 읽어온 다음 이를 통해 호출해야합니다.
        } else if indexPath.row == 5 { // 계정 관리
            let uv = self.storyboard?.instantiateViewController(withIdentifier: "_Profile")
            self.present(uv!, animated: true) {
                self.revealViewController()?.revealToggle(self)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        self.nameLabel.text = self.uinfo.name ?? "Guest"
        self.emailLabel.text = self.uinfo.account ?? ""
        self.profileImage.image = self.uinfo.profile
    }
}
