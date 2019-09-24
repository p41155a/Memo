//
//  DataSync.swift
//  Memo
//
//  Created by MC975-107 on 25/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class DataSync {
    // 코어 데이터의 컨텍스트 객체
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    // 서버에 백업자료 다운로드
    func downloadBackupData() {
        // 최초 한 번만 다운로드
        let ud = UserDefaults.standard
        guard ud.value(forKey: "firstLogin") == nil else { return }
        // API 호출용 인증 헤더
        let tk = TokenUtils()
        let header = tk.getAuthorizationHeader()
        // API 호출
        let url = "http://swiftapi.rubypaper.co.kr:2029/memo/search"
        let get = Alamofire.request(url, method: .post, encoding: JSONEncoding.default, headers: header)
        // 응답 처리
        get.responseJSON { res in
            // 응답 결과가 잘못되거나 list 항목이 없는 경우 종료
            guard let jsonObject = res.result.value as? NSDictionary else { return }
            guard let list = jsonObject["list"] as? NSArray else { return }
            // list 항목을 순회하면서 데이터를 코어 데이터에 저장
            for item in list {
                guard let record = item as?  NSDictionary else { return }
                // MemoMO 타입의 관리 객체 인스턴스 생성, 속성에 값을 대입
                let object = NSEntityDescription.insertNewObject(forEntityName: "Memo", into: self.context) as! MemoMO
                object.title = (record["title"] as! String)
                object.contents = (record["contents"] as! String)
                object.regdate = self.stringToDate(record["create_date"] as! String)
                object.sync = true
                // 이미지가 있을 경우
                if let imagePath = record["image_path"] as? String {
                    let url = URL(string: imagePath)!
                    object.image = try! Data(contentsOf: url)
                }
            }
            // 영구 저장소에 커밋
            do {
                try self.context.save()
            } catch let e as NSError {
                self.context.rollback()
                NSLog("An error has occurred: %s", e.localizedDescription)
            }
            // 다운로드가 끝났으므로 이후에는 실행 되지않게 처리
            ud.set(true, forKey: "firstLogin")
        }
    }
    // Memo 엔터티에 저장된 모든 데이터 중에서 동기화되지 않은 것을 찾아 업로드한다.
    func uploadData() {
        // 요청 객체 생성
        let fetchRequest: NSFetchRequest<MemoMO> = MemoMO.fetchRequest()
        // 최신 글 순으로 정렬
        let regdateDesc = NSSortDescriptor(key: "regdate", ascending: false)
        fetchRequest.sortDescriptors = [regdateDesc]
        // 업로드가 되지 않은 데이터만 추출
        fetchRequest.predicate = NSPredicate(format: "sync == false")
        do {
            let resultset = try self.context.fetch(fetchRequest)
            // 읽어온 결과 집합을 순회하면서 [MemoData] 타입으로 변환
            for record in resultset {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                print("upload Data == \(record.title!)")
                // 서버에 업로드
                self.uploadDatum(record) {
                    if record === resultset.last { // 마지막 데이터의 업로드가 끝나면
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // 인자값으로 입력된 개별 MemoMO 객체를 서버에 업로드한다.
    func uploadDatum(_ item: MemoMO, complete: (()->Void)? = nil) {
        // 헤더 설정
        let tk = TokenUtils()
        guard let header = tk.getAuthorizationHeader() else {
            print("로그인 상태가 아니므로 [\(item.title!)]를 업로드할 수 없습니다")
            return
        }
        // 전송할 값 설정
        var param: Parameters = [
            "title": item.title!,
            "content": item.contents!,
            "create_date": self.dateToString(item.regdate!)
        ]
        // 이미지가 있을 경우 이미지도 전송할 값에 포함
        if let imageData = item.image as Data? {
            param["image"] = imageData.base64EncodedString()
        }
        // 전송
        let url = "http://swiftapi.rubypaper.co.kr:2029/memo/save"
        let upload = Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default, headers: header)
        // 응답 및 결과 처리
        upload.responseJSON { res in
            guard let jsonObject = res.result.value as? NSDictionary else {
                print("잘못된 응답입니다")
                return
            }
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 {
                print("[\(item.title!)]이(가) 등록되었습니다.")
                // 코어 데이터에 반영
                do {
                    item.sync = true
                    try self.context.save()
                } catch let e as NSError {
                    self.context.rollback()
                    NSLog("An error has occurred: %s", e.localizedDescription)
                }
            } else {
                print(jsonObject["error_msg"] as! String)
            }
            // 완료 처리 클로저 실행
            complete?()
        }
    }
}

extension DataSync { // 기본적으로 앱과 서버 사이에서 주고 받는 것은 날짜 형식은 모두 문자열로 처리 되므로 메소드 구현이 필요
    // String -> Date
    func stringToDate(_ value: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: value)!
    }
    // Date -> String
    func dateToString(_ value: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: value as Date)
    }
}
