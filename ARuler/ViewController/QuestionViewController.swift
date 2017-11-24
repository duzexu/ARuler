//
//  QuestionViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/25.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import LeanCloudFeedback

class QuestionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func moreInfoAction(_ sender: UIButton) {
        let vc = LCUserFeedbackViewController()
        vc.presented = false
        vc.navigationBarStyle = LCUserFeedbackNavigationBarStyleNone
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
