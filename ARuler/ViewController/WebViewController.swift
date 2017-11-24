//
//  WebViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/22.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import SafariServices
import SnapKit

class WebViewController: UIViewController {
    
    var web: SFSafariViewController!
    var _url: URL?
    
    init(url: String) {
        super.init(nibName: nil, bundle: nil)
        _url = URL(string: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = _url {
            web = SFSafariViewController(url: url)
            web.delegate = self
            self.addChildViewController(web)
            self.view.addSubview(web.view)
            web.view.snp.makeConstraints { (make) in
                make.edges.equalTo(self.view)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WebViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}
