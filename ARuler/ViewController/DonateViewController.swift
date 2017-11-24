//
//  DonateViewController.swift
//  ARuler
//
//  Created by duzexu on 2017/9/24.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import UIKit
import PKHUD

class DonateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func donateAction(_ sender: UIButton) {
        if sender.tag == 1 && UIApplication.shared.canOpenURL(URL(string: "alipay://")!) {
            let url = "https://qr.alipay.com/FKX051081LORZHOWMWNHCE"
            UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
        }else{
            let image = sender.tag == 0 ? R.image.wxJpg() : R.image.zfbJpg()
            UIImageWriteToSavedPhotosAlbum(image!, self, #selector(imageSaved(image:error:context:)), nil)
        }
    }
    
    @objc func imageSaved(image: UIImage, error: Error?, context: UnsafeMutableRawPointer?) -> Void {
        if error == nil {
            HUD.flash(.label("二维码已保存到相册"), delay:1.5)
        }else{
            HUD.flash(.label("保存失败\n请到设置页面打开相册权限"), delay:1.5)
        }
    }
}
