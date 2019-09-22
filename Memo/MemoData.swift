//
//  MemoData.swift
//  Memo
//
//  Created by MC975-107 on 12/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class MemoData {
    var memoIdx : Int? // 데이터 식별값
    var title : String? // 메모 제목
    var contents : String? // 메모 내용
    var image : UIImage? // 이미지
    var regdate : Date? // 작성일
    // 원본 MemoMO 객체를 참조하기 위한 속성
    var objectID: NSManagedObjectID?
}
