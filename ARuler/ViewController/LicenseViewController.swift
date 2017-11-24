//
//  LicenseViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/22.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit

class LicenseViewController: UITableViewController {
    
    var licenses:Dictionary<String,Any>!

    override func viewDidLoad() {
        super.viewDidLoad()
        licenses = ["OpenCV":"https://github.com/opencv/opencv","LeanCloudFeedback":"https://github.com/leancloud/ios-feedback-demo","R.swift":"https://github.com/mac-cain13/R.swift","SnapKit":"https://github.com/SnapKit/SnapKit","PKHUD":"https://github.com/pkluz/PKHUD"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LicenseViewController {
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return licenses.keys.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.font = UIFont.systemFont(ofSize: 14)
        header.textColor = UIColor.headerTextColor
        header.text = "    感谢以下开源项目"
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.licenseCell.identifier, for: indexPath)
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textColor = UIColor.textColor
        let key = Array(licenses.keys)[indexPath.row]
        cell.textLabel?.text = key
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = Array(licenses.keys)[indexPath.row]
        let vc = WebViewController(url: licenses[key] as! String)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
