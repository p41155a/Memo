//
//  MemoDAO.swift
//  Memo
//
//  Created by MC975-107 on 22/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit
import CoreData
class MemoDAO {
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    func fetch(keyword text: String? = nil) -> [MemoData] {
        var memolist = [MemoData]()
        // 요청 객체 생성
        let fetchRequest: NSFetchRequest<MemoMO> = MemoMO.fetchRequest()
        // 최신 글 순으로 정렬하도록
        let regdateDesc = NSSortDescriptor(key: "regdate", ascending: false)
        fetchRequest.sortDescriptors = [regdateDesc]
        // 검색 키워드가 있을 경우 검색 조건 추가
        if let t = text, t.isEmpty == false {
            fetchRequest.predicate = NSPredicate(format: "contents CONTAINS[c] %@", t)
        }
        // 영구 저장소에 변경사항을 저장한다.
        do {
            let resultset = try self.context.fetch(fetchRequest)
            // 읽어온 결과 집합을 순회하면서 [MemoData] 타입으로 변환
            for record in resultset {
                // MemoData 객체 생성
                let data = MemoData()
                // MemoMO 프로퍼티 값을 MemoData의 프로퍼티로 복사
                data.title = record.title
                data.contents = record.contents
                data.regdate = record.regdate! as Date
                data.objectID = record.objectID
                
                // 이미지가 있을 때 복사
                if let image = record.image as Data? {
                    data.image = UIImage(data: image)
                }
                
                // MemoData 객체를 memolist 배열에 추가
                memolist.append(data)
            }
        } catch let e as NSError {
            NSLog("An error has occurred: %s", e.localizedDescription)
        }
        return memolist
    }
    
    func insert(_ data: MemoData) {
        // 관리 객체 인스턴스 생성
        let object = NSEntityDescription.insertNewObject(forEntityName: "Memo", into: self.context) as! MemoMO
        // MemoData로부터 값을 복사
        object.title = data.title
        object.contents = data.contents
        object.regdate = data.regdate
        if let image = data.image {
            object.image = image.pngData()
        }
        // 영구 저장소에 변경 사항을 반영
        do {
            try self.context.save()
            // 로그인되어 있을 경우 서버에 데이터를 업로드한다.
            let tk = TokenUtils()
            if tk.getAuthorizationHeader() != nil {
                DispatchQueue.global(qos: .background).async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    // 서버에 데이터를 업로드함
                    let sync = DataSync()
                    sync.uploadDatum(object) {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
            }
        } catch let e as NSError {
            NSLog("An error has occurred: %s", e.localizedDescription)
        }
    }
    
    func delete(_ objectID: NSManagedObjectID) -> Bool {
        // 삭제할 객체를 찾고 컨텍스트에서 삭제
        let object = self.context.object(with: objectID)
        self.context.delete(object)
        
        // 영구 저장소에 변경 사항을 반영
        do {
            try self.context.save()
            return true
        } catch let e as NSError {
            NSLog("An error has occurred: %s", e.localizedDescription)
            return false
        }
    }
}

