//
//  SupportViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/21.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices

class SupportViewController: UIViewController {

    var values: Array<String>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        SKStoreReviewController.requestReview()
        values = ["去 APP Store 评价","分享给你的朋友","给此开源项目 Star","打赏作者"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SupportViewController : UITableViewDelegate,UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.font = UIFont.systemFont(ofSize: 14)
        header.textColor = UIColor.headerTextColor
        header.text = "    可以通过以下方式表达对ARuler的支持"
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.supportCell.identifier, for: indexPath)
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textColor = UIColor.textColor
        cell.textLabel?.text = values[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let url = "itms-apps://itunes.apple.com/app/id1255077231?action=write-review"
            UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
            break
        case 1:
            let share = UIActivityViewController(activityItems: [R.image.logo()!,URL(string: "https://itunes.apple.com/us/app/aruler/id1255077231?l=zh&mt=8")!,"我正在使用ARuler测距离，快来试试吧！"], applicationActivities: nil)
            self.navigationController?.present(share, animated: true, completion: nil)
            break
        case 2:
            let vc = WebViewController(url: "https://github.com/duzexu/ARuler")
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 3:
            self.navigationController?.pushViewController(R.storyboard.main.donateViewController()!, animated: true)
            break
        default:
            break
        }
    }
}

