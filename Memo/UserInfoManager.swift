import UIKit
import Alamofire

struct UserInfoKey {
    // 저장에 사용할 키
    static let loginId = "LOGINID"
    static let account = "ACCOUNT"
    static let name = "NAME"
    static let profile = "PROFILE"
    static let tutorial = "TUTORIAL"
}
// 계정 및 사용자 정보를 저장 관리하는 클래스
class UserInfoManager {
    var loginid: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserInfoKey.loginId)
        }
        set(v) {
            let ud = UserDefaults.standard
            ud.set(v, forKey: UserInfoKey.loginId)
            ud.synchronize()
        }
    }
    var account: String? {
        get {
            return UserDefaults.standard.string(forKey: UserInfoKey.account)
        }
        set(v) {
            let ud = UserDefaults.standard
            ud.set(v, forKey: UserInfoKey.account)
            ud.synchronize()
        }
    }
    var name: String? {
        get {
            return UserDefaults.standard.string(forKey: UserInfoKey.name)
        }
        set(v) {
            let ud = UserDefaults.standard
            ud.set(v, forKey: UserInfoKey.name)
            ud.synchronize()
        }
    }
    var profile: UIImage? {
        get {
            let ud = UserDefaults.standard
            if let _profile = ud.data(forKey: UserInfoKey.profile) {
                return UIImage(data: _profile)
            } else {
                return UIImage(named: "account.jpg")
            }
        }
        set(v) {
            if v != nil {
                let ud = UserDefaults.standard
                ud.set(v!.pngData(), forKey: UserInfoKey.profile)
                ud.synchronize()
            }
        }
    }
    var isLogin: Bool {
        // 로그인 아이디가 0이거나 계정이 비어있으면
        if self.loginid == 0 || self.account == nil {
            return false
        } else {
            return true
        }
    }
    func login(account: String, passwd: String, success: (()->Void)? = nil, fail: ((String)->Void)? = nil) {
        // URL, 전송할 값 준비
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/login"
        let param: Parameters = [
            "account": account,
            "passwd": passwd
        ]
        // API 호출
        let call = Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default)
        // API 호출 결과 처리
        call.responseJSON { res in
            // JSON 형식으로 응답했는지 확인
            guard let jsonObject = res.result.value as? NSDictionary else {
                fail?("잘못된 응답 형식입니다:\(res.result.value!)")
                return
            }
            // 응답 코드 확인
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 { // 성공
                let user = jsonObject["user_info"] as! NSDictionary
                
                self.loginid = user["user_id"] as! Int
                self.account = user["account"] as? String
                self.name = user["name"] as? String
                
                // 프로필 이미지 처리
                if let path = user["profile_path"] as? String {
                    if let imageData = try? Data(contentsOf: URL(string: path)!) {
                        self.profile = UIImage(data: imageData)
                    }
                }
                // 토큰 정보 추출
                let accessToken = jsonObject["access_token"] as! String // 액세스 토큰 추출
                let refreshToken = jsonObject["refresh_token"] as! String // 리프레시 토큰 추출
                // 토큰 정보 저장
                let tk = TokenUtils()
                tk.save("kr.ac.induk.comso.Memo", account: "accessToken", value: accessToken)
                tk.save("kr.ac.induk.comso.Memo", account: "refreshToken", value: refreshToken)
                // 인자값으로 입력된 클로저 블록 실행
                success?()
            } else { // 실패
                let msg = (jsonObject["error_msg"] as? String) ?? "로그인이 실패했습니다"
                fail?(msg)
            }
        }
    }
    func logout() -> Bool {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: UserInfoKey.loginId)
        ud.removeObject(forKey: UserInfoKey.account)
        ud.removeObject(forKey: UserInfoKey.name)
        ud.removeObject(forKey: UserInfoKey.profile)
        ud.synchronize()
        return true
    }
    
    func logout(completion: (()->Void)? = nil) {
        // 호출 URL
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/logout"
        // 인증 헤더 구현
        let tokenUtils = TokenUtils()
        let header = tokenUtils.getAuthorizationHeader()
        // API 호출 및 응답 처리
        let call = Alamofire.request(url, method: .post, encoding: JSONEncoding.default, headers: header)
        call.responseJSON { _ in
            // 서버로부터 응답이 온 후 처리할 동작
            self.localLogout()
            completion?()
        }
    }
    
    func localLogout() {
        // 기본 저장소에 저장된 값을 모두 삭제
        let ud = UserDefaults.standard
        ud.removeObject(forKey: UserInfoKey.loginId)
        ud.removeObject(forKey: UserInfoKey.account)
        ud.removeObject(forKey: UserInfoKey.name)
        ud.removeObject(forKey: UserInfoKey.profile)
        ud.synchronize()
        // 키 체인에 저장된 값을 모두 삭제
        let tokenUtils = TokenUtils()
        tokenUtils.delete("kr.ac.induk.comso.Memo", account: "refreshToken")
        tokenUtils.delete("kr.ac.induk.comso.Memo", account: "accessToken")
    }
    
    func newProfile(_ profile: UIImage?, success: (()->Void)? = nil, fail: ((String)->Void)? = nil) {
        // API 호출 URL
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/profile"
        // 인증 헤더
        let tk = TokenUtils()
        let header = tk.getAuthorizationHeader()
        // 전송할 프로필 이미지
        let profileData = UIImage.pngData(profile!)()?.base64EncodedString()
        let param: Parameters = ["profile_image" : profileData!]
        // 이미지 전송
        let call = Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default, headers: header)
        call.responseJSON { res in
            guard let jsonObject = res.result.value as? NSDictionary else {
                fail?("올바른 응답값이 아닙니다.")
                return
            }
            // 응답 코드 확인. 0이면 성공
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 {
                self.profile = profile // 이미지가 업로드 되었다면 UserDefault에 저장된 이미지도 변경한다.
                success?()
            } else {
                let msg = (jsonObject["error_msg"] as? String) ?? "이미지 프로필 변경이 실패했습니다."
                fail?(msg)
            }
        }
    }
}
