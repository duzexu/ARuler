//
//  SettingViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/21.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import LeanCloudFeedback

class SettingViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    static let lengthUnitKey = "kUserDefault_lengthUnitKey"
    
    var sections: Array<String>!
    var values: Array<Array<String>>!
    
    var segment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        sections = ["测量设置","使用帮助","ARuler"]
        values = [["长度单位"],["新手教程","常见问题"],["支持 ARuler","吐槽 ARuler","关于 ARuler"]]
        
        let items = Float.unit.map { (lengthUnit) -> String in
            return lengthUnit.rate.1
        }
        segment = UISegmentedControl(items: items)
        segment.tintColor = UIColor.themeColor
        segment.addTarget(self, action: #selector(lengthUnitChanged(sender:)), for: .valueChanged)
        let defaultUnit = UserDefaults.standard.integer(forKey: SettingViewController.lengthUnitKey)
        segment.selectedSegmentIndex = defaultUnit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension SettingViewController {
    @objc func lengthUnitChanged(sender: UISegmentedControl) -> Void {
        UserDefaults.standard.setValue(sender.selectedSegmentIndex, forKey: SettingViewController.lengthUnitKey)
    }
}

extension SettingViewController : UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values[section].count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.font = UIFont.systemFont(ofSize: 14)
        header.textColor = UIColor.headerTextColor
        let key = sections[section]
        header.text = "    " + "\(key)"
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.settingCell.identifier, for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textColor = UIColor.textColor
        cell.textLabel?.text = values[indexPath.section][indexPath.row]
        
        if indexPath.section == 0 {
            cell.accessoryView = segment
        }else{
            cell.accessoryView = nil
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                self.navigationController?.pushViewController(R.storyboard.main.guideViewController()!, animated: true)
                break
            case 1:
                self.navigationController?.pushViewController(R.storyboard.main.questionViewController()!, animated: true)
                break
            default: break
            }
            break
        case 2:
            switch indexPath.row {
            case 0:
                self.navigationController?.pushViewController(R.storyboard.main.supportViewController()!, animated: true)
                break
            case 1:
                let vc = LCUserFeedbackViewController()
                vc.presented = false
                vc.navigationBarStyle = LCUserFeedbackNavigationBarStyleNone
                self.navigationController?.pushViewController(vc, animated: true)
                break
            case 2:
                self.navigationController?.pushViewController(R.storyboard.main.aboutViewController()!, animated: true)
                break
            default: break
            }
            break
        default: break
        }
    }
    
}
