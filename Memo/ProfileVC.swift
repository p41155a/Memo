//
//  ProfileVC.swift
//  Memo
//
//  Created by MC975-107 on 16/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit
import Alamofire
import LocalAuthentication

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var isCalling = false // API 중복 호출 관리
    let uinfo = UserInfoManager() // 개인 정보 관리 매니저
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
        let image = self.uinfo.profile
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
        
        // 로그인/ 로그아웃 버튼을 출력
        self.drawBtn()
        // 프로필 사진 화면 클릭 시
        let tap = UITapGestureRecognizer(target: self, action: #selector(profile(_:)))
        self.profileImage.addGestureRecognizer(tap)
        self.profileImage.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 토큰 인증 여부 체크
        self.tokenValidate()
    }
    
    @objc func close(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
        // 프로필 화면으로의 전환은 프레젠트 메소드 방식으로 처리될 예정(전체 화면을 덮듯이)이기 때문에 dismiss(animated:) 메소드를 사용
    }
    
    @objc func doLogin(_ sender: Any) {
        if self.isCalling == true {
            self.alert("응답을 기다리는 중입니다. \n잠시만 기다려 주세요")
            return
        } else {
            self.isCalling = true
        }
        let loginAlert = UIAlertController(title: "LOGIN", message: nil, preferredStyle: .alert)
        // 알림창에 들어갈 입력폼 추가
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Your Account"
        }
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Password"
            tf.isSecureTextEntry = true
        }
        // 알림창 버튼 추가
        loginAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.isCalling = false
        })
        loginAlert.addAction(UIAlertAction(title: "Login", style: .destructive) { (_) in
            // 네트워크 인디케이터 실행
            UIApplication.shared.isNetworkActivityIndicatorVisible = true // 네트워크 인디케이터 시작
            let account = loginAlert.textFields?[0].text ?? ""
            let passwd = loginAlert.textFields?[1].text ?? ""
            
            // 비동기 방식으로 변경
            self.uinfo.login(account: account, passwd: passwd, success: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false // 네트워크 인디케이터 종료
                self.isCalling = false
                self.tv.reloadData() // 테이블 뷰 갱신
                self.profileImage.image = self.uinfo.profile // 이미지 프로필 갱신
                self.drawBtn()
                // 서버와 데이터 동기화
                let sync = DataSync()
                DispatchQueue.global(qos: .background).async {
                    sync.downloadBackupData() // 서버에 저장된 데이터가 있으면 내려받는다
                }
                DispatchQueue.global(qos: .background).async {
                    sync.uploadData() // 서버에 저장해야 할 데이터가 있으면 업로드한다.
                }
            }, fail: { msg in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false // 네트워크 인디케이터 종료
                self.isCalling = false
                self.alert(msg)
            })
        })
        self.present(loginAlert, animated: false)
    }
    
    // 로그아웃 메서드
    @objc func doLogout(_ sender: Any) {
        let msg = "로그아웃하시겠습니까?"
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { (_) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.uinfo.logout() {
                // 로그아웃 처리할 내용
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.tv.reloadData() // 테이블 뷰를 갱신하다
                self.profileImage.image = self.uinfo.profile // 이미지 프로필을 갱신한다.
                self.drawBtn() // 로그인/로그아웃 버튼을 출력한다
                }
        })
        self.present(alert, animated: false)
    }
    
    @objc func profile(_ sender: UIButton) {
        // 로그인 되어있지 않으면 로그인 창을 띄움
        guard self.uinfo.account != nil else {
            self.doLogin(self)
            return
        }
        let alert = UIAlertController(title: nil, message: "사진을 가져올 곳을 선택해 주세요", preferredStyle: .actionSheet)
        
        // 카메라
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "카메라", style: .default) { (_) in
                self.imgPicker(.camera)
            })
        }
        // 저장된 앨범
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            alert.addAction(UIAlertAction(title: "저장된 앨범", style: .default) { (_) in
                self.imgPicker(.savedPhotosAlbum)
            })
        }
        
        // 포토 라이브러리
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "포토 라이브러리", style: .default) { (_) in
                self.imgPicker(.photoLibrary)
            })
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        self.present(alert, animated: true)
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
            cell.detailTextLabel?.text = self.uinfo.name ?? "Login please"
        case 1:
            cell.textLabel?.text = "계정"
            cell.detailTextLabel?.text = self.uinfo.account ?? "Login please"
        default:
            ()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.uinfo.isLogin == false {
            self.doLogin(self.tv)
        }
    }
    
    // 로그인 / 로그아웃 버튼
    func drawBtn() {
        let v = UIView()
        v.frame.size.width = self.view.frame.width
        v.frame.size.height = 40
        v.frame.origin.x = 0
        v.frame.origin.y = self.tv.frame.origin.y + self.tv.frame.height
        v.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        
        self.view.addSubview(v)
        
        let btn = UIButton(type: .system)
        btn.frame.size.width = 100
        btn.frame.size.height = 30
        btn.center.x = v.frame.size.width / 2
        btn.center.y = v.frame.size.height / 2
        
        if self.uinfo.isLogin == true {
            btn.setTitle("로그아웃", for: .normal)
            btn.addTarget(self, action: #selector(doLogout(_:)), for: .touchUpInside)
        } else {
            btn.setTitle("로그인", for: .normal)
            btn.addTarget(self, action: #selector(doLogin(_:)), for: .touchUpInside)
        }
        v.addSubview(btn)
    }
    
    func imgPicker(_ source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true)
    }
    
    // 이미지 선택시 호출됨
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 네트워크 인디케이터 실행
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.uinfo.newProfile(img, success:  {
                // 네트워크 인디케이터 종료
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.profileImage.image = img
            }, fail: {msg in
                // 네트워크 인디케이터 종료
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.alert(msg)
            })
        }
        picker.dismiss(animated: true)
    }
    
    @IBAction func backProfileVC(_ segue: UIStoryboardSegue) {
        // 단지 프로필 화면으로 되돌아오기 위한 표식역활만 할뿐 아무 내용도 작성하지 않으
    }
}

extension ProfileVC {
    // 토큰 인증 메서드
    func tokenValidate() {
        // 응답 캐시 삭제
        URLCache.shared.removeAllCachedResponses()
        // 키 체인에 액세스 토큰이 없는 경우 유효성 검사를 하지 않음
        let tk = TokenUtils()
        guard let header = tk.getAuthorizationHeader() else {
            return
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // tokenValidate API 호출
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/tokenValidate"
        let validate = Alamofire.request(url, method: .post, encoding: JSONEncoding.default, headers: header)
        validate.responseJSON { res in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            //print("응답결과: \(res.result.value!)") // 응답 결과 확인
            guard let jsonObject = res.result.value as? NSDictionary else {
                self.alert("잘못된 응답입니다.")
                return
            }
            // 응답 결과 처리
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode != 0 { // 결과가 실패
                // 로컬 인증 실행
                self.touchID()
            }
        }
    }
    
    // 터치 아이디 인증 메서드
    func touchID() {
        // LAContext 인스턴스 생성
        let context = LAContext()
        // 로컬 인증에 사용할 변수
        var error: NSError?
        let msg = "인증이 필요합니다"
        let deviceAuth = LAPolicy.deviceOwnerAuthenticationWithBiometrics // 인증 정책
        // 로컬 인증이 사용 가능한지
        if context.canEvaluatePolicy(deviceAuth, error: &error) {
            // 터치 아이디 인증창
            context.evaluatePolicy(deviceAuth, localizedReason: msg) { (success, e) in
                if success { // 인증 성공
                    // 토큰 갱신 로직
                    self.refresh()
                } else { // 인증 실패
                    // 인증 실패 로직
                    print((e?.localizedDescription)!)
                    switch (e!._code) {
                    case LAError.systemCancel.rawValue:
                        self.alert("시스템에 의해 인증이 취소되었습니다")
                    case LAError.userCancel.rawValue:
                        self.alert("사용자에 의해 인증이 취소되었습니다.")
                        self.commonLogout(true)
                    case LAError.userFallback.rawValue:
                        OperationQueue.main.addOperation {
                            self.commonLogout(true)
                        }
                    default:
                        OperationQueue.main.addOperation {
                            self.commonLogout(true)
                        }
                    }
                }
            }
        } else { // 인증창 실행 못한 경우
            print(error!.localizedDescription)
            switch (error!.code) {
            case LAError.biometryNotEnrolled.rawValue:
                print("터치 아이디가 등록되어 있지 않습니다")
            case LAError.passcodeNotSet.rawValue:
                print("패스 코드가 설정되어 있지 않습니다")
            default:
                print("터치 아이디를 사용할 수 없습니다")
            }
            OperationQueue.main.addOperation {
                self.commonLogout(true)
            }
        }
    }
    
    // 토큰 갱신 메서드
    func refresh() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // 인증 헤더
        let tk = TokenUtils()
        let header = tk.getAuthorizationHeader()
        // 리프레시 토큰 전달 준비
        let refreshToken = tk.load("com.nanocode.MyMemory", account: "refreshToken")
        let param: Parameters = ["refresh_token": refreshToken!]
        // 호출
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/refresh"
        let refresh = Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default, headers: header)
        refresh.responseJSON { res in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard let jsonObject = res.result.value as? NSDictionary else {
                self.alert("잘못된 응답입니다")
                return
            }
            // 응답 결과 처리
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 { // 성공
                // 키 체인에 저장된 액세스 토큰 교체
                let accessToken = jsonObject["access_token"] as! String
                tk.save("com.nanocode.MyMemory", account: "accountToken", value: accessToken)
            } else { // 실패
                self.alert("인증이 만료되었습니다. 다시 로그인해 주세요")
                OperationQueue.main.addOperation {
                    self.commonLogout(true)
                }
            }
        }
    }
    // 토큰 갱신에 실패하거나 오류가 발생했을 때, 개인 정보 삭제 후 로그아웃 상태로 전환
    func commonLogout(_ isLogin: Bool = false) {
        // 저장된 기존 개인 정보/키 체인 삭제 후 로그아웃
        let userInfo = UserInfoManager()
        userInfo.localLogout()
        // 현재 화면이 프로필 화면이면 바로 UI 갱신
        self.tv.reloadData()
        self.profileImage.image = userInfo.profile
        self.drawBtn()
        // 기본 로그인 창 실행 여부
        if isLogin {
            self.doLogin(self)
        }
    }
}
