//
//  TutorialMasterVC.swift
//  Memo
//
//  Created by MC975-107 on 17/09/2019.
//  Copyright © 2019 comso. All rights reserved.
//

import UIKit

class TutorialMasterVC: UIViewController, UIPageViewControllerDataSource {
    
    var pageVC: UIPageViewController!
    var contentTitles = ["STEP 1", "STEP 2", "STEP 3", "STEP 4" ]
    var contentImages = ["page0", "page1", "page2", "page3"]
    
    @IBAction func close(_ sender: Any) {
        let ud = UserDefaults.standard
        ud.set(true, forKey: UserInfoKey.tutorial)
        ud.synchronize()
        
        self.presentingViewController?.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 페이지 뷰 컨트롤러 객체 생성
        self.pageVC = self.instanceTutorialVC(name: "PageVC") as? UIPageViewController
        self.pageVC.dataSource = self
        // 페이지 뷰 컨트롤러의 기본 페이지 지정
        let startContentVC = self.getContentVC(atIndex: 0)!
        self.pageVC.setViewControllers([startContentVC], direction: .forward, animated: true)
        // 페이지 뷰 컨트롤러 출력 영역
        self.pageVC.view.frame.origin = CGPoint(x: 0, y: 0)
        self.pageVC.view.frame.size.width = self.view.frame.width
        self.pageVC.view.frame.size.height = self.view.frame.height - 90
        // 페이지 뷰 컨트롤러를 마스터 뷰 컨트롤러의 자식 뷰 컨트롤러로 지정
        self.addChild(self.pageVC)
        self.view.addSubview(self.pageVC.view)
        self.pageVC.didMove(toParent: self)
    }
    
    func getContentVC(atIndex idx: Int) -> UIViewController? {
        // 인덱스가 데이터 배열 크기 범위를 벗어나면 nil 반환
        guard self.contentTitles.count >= idx && self.contentTitles.count > 0 else {
            return nil
        }
        // stroyboard ID가 ContentsVC인 뷰 컨트롤러의 인스턴스를 생성하고 캐스팅
        guard let cvc = self.instanceTutorialVC(name: "ContentsVC") as? TutorialContentsVC else {
            return nil
        }
        cvc.titleText = self.contentTitles[idx]
        cvc.imageFile = self.contentImages[idx]
        cvc.pageIndex = idx
        return cvc
    }
    
    // 현재의 콘텐츠 뷰 컨트롤러보다 앞쪽에 올 콘텐츠 뷰 컨트롤러 객체
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard var index = (viewController as! TutorialContentsVC).pageIndex else{
            return nil
        }
        guard index > 0 else {
            return nil
        }
        index -= 1 // 현재의 인덱스에서 하나 뺌 (즉, 이전 페이지 인덱스)
        return self.getContentVC(atIndex: index)
    }
    
    // 현재의 콘텐츠 뷰 컨트롤러보다 뒤쪽에 올 콘텐츠 뷰 컨트롤러 객체
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 현재의 페이지 인덱스
        guard var index = (viewController as! TutorialContentsVC).pageIndex else {
            return nil
        }
        index += 1 // 현재의 인덱스에 하나를 더함(즉, 다음 페이지 인덱스)
        // 인덱스는 항상 배열 데이터의 크기보다 작아야 한다.
        guard index < self.contentTitles.count else {
            return nil
        }
        return self.getContentVC(atIndex: index)
    }
    
    // 페이지 뷰 컨트롤러가 출력할 페이지의 개수를 알려주는 메서드
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.contentTitles.count
    }
    
    // 페이지 뷰 컨트롤러가 최초에 출력할 콘텐츠 뷰의 인덱스를 알려주는 메서드
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
